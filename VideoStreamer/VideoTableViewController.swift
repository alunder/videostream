//
//  VideoTableViewController.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/25/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class VideoTableViewController: UITableViewController, UITextFieldDelegate {
    
    var videos = [Video]()
    let playerController = AVPlayerViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSampleVideos()
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    struct Storyboard {
        static let VideoCellIdentifier = "VideoCell"
    }
    
    private func loadSampleVideos() {
        saveVideoFromString("http://techslides.com/demos/sample-videos/invalid-video.mp4")
        saveVideoFromString("http://techslides.com/demos/sample-videos/small.mp4")
        
    }
    
    @IBAction func addStream(sender: UIBarButtonItem) {
        let videoLinkAlert = UIAlertController(title: "New Video Stream", message: nil, preferredStyle: .Alert)
        var linkField: UITextField!
        
        // Set up textField to enter link
        videoLinkAlert.addTextFieldWithConfigurationHandler { (textField) in
            textField.delegate = self
            textField.placeholder = "http://"
            textField.enablesReturnKeyAutomatically = true
            textField.addTarget(self, action: #selector(VideoTableViewController.textChanged(_:)), forControlEvents: .EditingChanged)
            linkField = textField
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        videoLinkAlert.addAction(cancelAction)
        let downloadAction = UIAlertAction(title: "Download", style: .Default) { (action) in
            self.saveVideoFromString(linkField.text!)
        }
        
        videoLinkAlert.addAction(downloadAction)
        downloadAction.enabled = false
        
        presentViewController(videoLinkAlert, animated: true, completion: nil)
        
    }
    
    func textChanged(sender: UITextField) {
        var resp: UIResponder = sender
        while !(resp is UIAlertController) { resp = resp.nextResponder()! }
        let alert = resp as? UIAlertController
        (alert!.actions[1] as UIAlertAction).enabled = (sender.text != "")
    }
    
    private func saveVideoFromString(urlString: String) {
        if let url = NSURL(string: urlString) where isValidURL(url) {
            let video = Video(url: url)
            self.videos.append(video)
            // FIXME: Reload relevant row
            tableView.reloadData()
        }
        else {
            let invalidLink = UIAlertController(title: "Invalid URL!", message: nil, preferredStyle: .Alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
            invalidLink.addAction(dismissAction)
            
            presentViewController(invalidLink, animated: true, completion: nil)
            
        }
    }
    
    private func isValidURL(url: NSURL) -> Bool {
        guard UIApplication.sharedApplication().canOpenURL(url) else {return false}
        return true
    }
    
    private func setupPlayerForVideo(video: Video) {
        let playerItem = AVPlayerItem(URL: video.url)
        let player = AVPlayer(playerItem: playerItem)
        playerController.player = player
        presentViewController(playerController, animated: true, completion: nil)
        playerItem.addObserver(self, forKeyPath: "status", options: .New, context: nil)
    }
    
    private func displayPlaybackErrorAlert() {
        playerController.dismissViewControllerAnimated(true) {
            let playbackError = UIAlertController(title: "An error occurred while loading this video", message: nil, preferredStyle: .Alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
            playbackError.addAction(dismissAction)
            
            self.presentViewController(playbackError, animated: true, completion: nil)
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let playerItem = object as? AVPlayerItem {
            if keyPath == "status" {
                playerItem.removeObserver(self, forKeyPath: "status")
                if playerItem.status == .ReadyToPlay {
                    playerController.player!.play()
                } else if playerItem.status == .Failed {
                    displayPlaybackErrorAlert()
                }
            }
        }
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.resignFirstResponder()
    }
    
    // MARK: - Table view data source
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.VideoCellIdentifier, forIndexPath: indexPath)
        
        if let videoCell = cell as? VideoTableViewCell {
            let video = videos[indexPath.row]
            videoCell.video = video
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            videos.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let video = videos[indexPath.row]
        setupPlayerForVideo(video)
    }
}
