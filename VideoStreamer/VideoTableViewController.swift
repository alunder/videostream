//
//  VideoTableViewController.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/25/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit

class VideoTableViewController: UITableViewController, UITextFieldDelegate {
    
    var videos = [Video]()
    var cachedVideoData = [URL : [String: Any]]() // associate video URL with videoInfo dictionary
    static let unsupportedFileTypes = ["flv"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let savedVideos = loadVideos() {
            videos += savedVideos
        } else {
            loadSampleVideos()
        }
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
        } else {
            // Fallback on earlier versions
        }
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        saveVideos()
    }
    
    struct Storyboard {
        static let VideoCellIdentifier = "VideoCell"
        static let AVPlayerVCSegue = "ShowPlayer"
        static let VideoInfoSegue = "ShowVideoInfo"
    }
    
    enum AlertType {
        case unplayableFileType
    }
    
    fileprivate func loadSampleVideos() {
        saveVideoFromString("http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4")
        saveVideoFromString("http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_1mb.mp4")
        saveVideoFromString("http://techslides.com/demos/sample-videos/small.mp4")
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
        let addAction = UIAlertAction(title: "Add", style: .default) { (action) in
            self.saveVideoFromString(linkField.text!)
        }
        
        videoLinkAlert.addAction(addAction)
        addAction.isEnabled = false
        
        present(videoLinkAlert, animated: true, completion: nil)
    }
    
    @objc func textChanged(_ sender: UITextField) {
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
    
    fileprivate func deleteThumbnail(forVideo video: Video) {
        let fileManager = FileManager.default
        let imagePath = (UIApplication.shared.delegate as! AppDelegate).imagesDirectoryPath + "/\(video.filename).png"
        do {
            try fileManager.removeItem(atPath: imagePath)
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    fileprivate func showAlert(for type: AlertType) {
        var alert: UIAlertController
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        
        switch type {
        case .unplayableFileType:
            alert = UIAlertController(title: "File type cannot be played!", message: nil, preferredStyle: .alert)
            alert.addAction(dismissAction)
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    // MARK: NSCoding
    func saveVideos() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(videos, toFile: Video.archiveURL.path)
        if !isSuccessfulSave {
            print("Failed to save videos...")
        }
    }
    
    func loadVideos() -> [Video]? {
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
            deleteVideo(forRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let infoAction = UITableViewRowAction(style: .normal, title: "Info") { (action, indexPath) in
            let cell = tableView.cellForRow(at: indexPath) as? VideoTableViewCell
            if !((cell?.videoInfo.isEmpty)!) {
                self.performSegue(withIdentifier: Storyboard.VideoInfoSegue, sender: cell)
            }
        }
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            self.deleteVideo(forRowAt: indexPath)
        }
        return [deleteAction, infoAction]
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = self.videos[sourceIndexPath.row]
        videos.remove(at: sourceIndexPath.row)
        videos.insert(movedObject, at: destinationIndexPath.row)
    }
    
    func deleteVideo(forRowAt indexPath: IndexPath) {
        let video = videos[indexPath.row]
        videos.remove(at: indexPath.row)
        deleteThumbnail(forVideo: video)
        let destination = Video.documentsDirectory.appendingPathComponent(video.filename)
        
        do {
            try FileManager.default.removeItem(at: destination)
        } catch {
            print(error.localizedDescription)
        }
        
        saveVideos()
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboard.AVPlayerVCSegue {
            if let playervc = segue.destination as? PlayerViewController {
                if let videoCell = sender as? VideoTableViewCell {
                    playervc.video = videoCell.video
                }
            }
        } else if segue.identifier == Storyboard.VideoInfoSegue {
            if let infovc = segue.destination as? VideoInfoViewController {
                if let videoCell = sender as? VideoTableViewCell {
                    infovc.video = videoCell.video
                    infovc.videoInfo = videoCell.videoInfo
                    infovc.thumbnailImage = videoCell.thumbnail.image
                }
            }
        }
        
    }
    
}
