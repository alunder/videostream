//
//  VideoTableViewController.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/25/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit
import AVKit

class VideoTableViewController: UITableViewController, UITextFieldDelegate, AVPlayerViewControllerDelegate {
    
    var videos = [Video]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let savedVideos = loadVideos() {
            videos += savedVideos
        } else {
            loadSampleVideos()
        }
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    struct Storyboard {
        static let VideoCellIdentifier = "VideoCell"
        static let AVPlayerVCSegue = "ShowPlayer"
    }
    
    fileprivate func loadSampleVideos() {
        saveVideoFromString("http://vevoplaylist-live.hls.adaptive.level3.net/vevo/ch1/appleman.m3u8")
        saveVideoFromString("http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4")
    }
    
    @IBAction func addStream(_ sender: UIBarButtonItem) {
        let videoLinkAlert = UIAlertController(title: "New Video Stream", message: nil, preferredStyle: .alert)
        var linkField: UITextField!
        
        // Set up textField to enter link
        videoLinkAlert.addTextField { (textField) in
            textField.delegate = self
            textField.placeholder = "http://"
            textField.enablesReturnKeyAutomatically = true
            textField.addTarget(self, action: #selector(VideoTableViewController.textChanged(_:)), for: .editingChanged)
            linkField = textField
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        videoLinkAlert.addAction(cancelAction)
        let downloadAction = UIAlertAction(title: "Download", style: .default) { (action) in
            self.saveVideoFromString(linkField.text!)
        }
        
        videoLinkAlert.addAction(downloadAction)
        downloadAction.isEnabled = false
        
        present(videoLinkAlert, animated: true, completion: nil)
    }
    
    func textChanged(_ sender: UITextField) {
        var resp: UIResponder = sender
        while !(resp is UIAlertController) { resp = resp.next! }
        let alert = resp as? UIAlertController
        (alert!.actions[1] as UIAlertAction).isEnabled = (sender.text != "")
    }
    
    fileprivate func saveVideoFromString(_ urlString: String) {
        if let url = URL(string: urlString) , isValidURL(url) {
            let video = Video(url: url, lastPlayedTime: nil)
            self.videos.insert(video, at: 0)
            let indexPath = IndexPath(row: videos.startIndex, section: 0)
            tableView.insertRows(at: [indexPath], with: .automatic)
            saveVideos()
        }
        else {
            let invalidLink = UIAlertController(title: "Unable to find URL", message: nil, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
            invalidLink.addAction(dismissAction)
            
            present(invalidLink, animated: true, completion: nil)
        }
    }
    
    fileprivate func isValidURL(_ url: URL) -> Bool {
        guard UIApplication.shared.canOpenURL(url) else {return false}
        return true
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    // MARK: NSCoding
    private func saveVideos() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(videos, toFile: Video.archiveURL.path)
        if !isSuccessfulSave {
            print("Failed to save videos...")
        }
    }
    
    private func loadVideos() -> [Video]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Video.archiveURL.path) as? [Video]
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.resignFirstResponder()
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.VideoCellIdentifier, for: indexPath)
        
        if let videoCell = cell as? VideoTableViewCell {
            let video = videos[(indexPath as NSIndexPath).row]
            videoCell.video = video
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            videos.remove(at: indexPath.row)
            saveVideos()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath != destinationIndexPath {
            swap(&videos[(sourceIndexPath as NSIndexPath).row], &videos[(destinationIndexPath as NSIndexPath).row])
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboard.AVPlayerVCSegue {
            if let playervc = segue.destination as? PlayerViewController {
                if let videoCell = sender as? VideoTableViewCell {
                    playervc.video = videoCell.video
                }
            }
        }
    }
    
}
