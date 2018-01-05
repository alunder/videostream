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
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    static let unsupportedFileTypes = ["flv"]
    
    struct Storyboard {
        static let VideoCellIdentifier = "VideoCell"
        static let AVPlayerVCSegue = "ShowPlayer"
        static let VideoInfoSegue = "ShowVideoInfo"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let savedVideos = loadVideos() {
            videos += savedVideos
        } else {
            loadSampleVideos()
        }
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = true
        }
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        saveVideos()
    }
    
    func loadSampleVideos() {
        saveVideoFromString("http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4")
        saveVideoFromString("http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_1mb.mp4")
        saveVideoFromString("http://techslides.com/demos/sample-videos/small.mp4")
    }
    
    @IBAction func addStream(_ sender: UIBarButtonItem) {
        let videoLinkAlert = UIAlertController(title: "New Video Stream", message: nil, preferredStyle: .alert)
        var linkField: UITextField!
        
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
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.resignFirstResponder()
    }
    
    func saveVideoFromString(_ urlString: String) {
        if let url = URL(string: urlString), isValidURL(url) {
            if VideoInfoManager.shared.cache[url] != nil {
                showAlert(for: .videoAlreadyExists)
                return
            }
            let video = Video(url: url, lastPlayedTime: nil)
            self.videos.insert(video, at: 0)
            let indexPath = IndexPath(row: videos.startIndex, section: 0)
            tableView.insertRows(at: [indexPath], with: .automatic)
            saveVideos()
        } else {
            showAlert(for: .invalidUrl)
        }
    }
    
    func isValidURL(_ url: URL) -> Bool {
        return UIApplication.shared.canOpenURL(url)
    }
    
    enum AlertType {
        case unplayableFileType, videoAlreadyExists, invalidUrl
    }
    
    func showAlert(for type: AlertType) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        
        switch type {
        case .unplayableFileType:
            alert.title = "File type cannot be played!"
        case .videoAlreadyExists:
            alert.title = "Video from URL already added"
        case .invalidUrl:
            alert.title = "URL was not in a valid format."
        }
        
        alert.addAction(dismissAction)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: NSCoding
    func saveVideos() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(videos, toFile: Video.archiveURL.path)
        if !isSuccessfulSave {
            print("Failed to save videos")
        }
    }
    
    func loadVideos() -> [Video]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Video.archiveURL.path) as? [Video]
    }
    
    func deleteVideo(forRowAt indexPath: IndexPath) {
        let video = videos[indexPath.row]
        videos.remove(at: indexPath.row)
        deleteThumbnail(forVideo: video)
        VideoInfoManager.shared.cache.removeValue(forKey: video.url)
        
        do {
            try FileManager.default.removeItem(at: video.getFilePath())
        } catch {
            print(error.localizedDescription)
        }
        
        saveVideos()
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    func deleteThumbnail(forVideo video: Video) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: video.getThumbnailPath())
        } catch {
            print(error.localizedDescription)
        }
    }
    
    // MARK: - TableView
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Storyboard.VideoCellIdentifier, for: indexPath)
        if let videoCell = cell as? VideoTableViewCell {
            let video = videos[indexPath.row]
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
            if let cell = tableView.cellForRow(at: indexPath) as? VideoTableViewCell {
                if !(cell.videoInfo.isEmpty) {
                    self.performSegue(withIdentifier: Storyboard.VideoInfoSegue, sender: cell)
                }
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
                    infovc.videoInfo = VideoInfoManager.shared.cache[infovc.video!.url]
                    infovc.thumbnailImage = videoCell.thumbnail.image
                }
            }
        }
    }
    
}
