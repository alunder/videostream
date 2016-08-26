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
    
    var videos = [NSURL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSampleVideos()
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    struct Storyboard {
        static let VideoCellIdentifier = "VideoCell"
        static let PlayVideoSegue = "PlayVideo"
    }
    
    private func loadSampleVideos() {
        downloadVideo("http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
        downloadVideo("http://techslides.com/demos/sample-videos/small.mp4")
        
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
            self.downloadVideo(linkField.text!)
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
    
    // TODO: Make run background
    private func downloadVideo(videoURL: String) {
        if let url = NSURL(string: videoURL) {
            if UIApplication.sharedApplication().canOpenURL(url) {
                
                self.videos.insert(url, atIndex: 0)
                self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
                
            } else {
                let invalidLink = UIAlertController(title: "Invalid URL", message: nil, preferredStyle: .Alert)
                let dismissAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
                invalidLink.addAction(dismissAction)
                
                self.presentViewController(invalidLink, animated: true, completion: nil)
                
            }
        }
    }
    
    // TODO: Make this run in utility queue
    private func getVideoThumbnail(sourceURL: NSURL) -> UIImage {
        let asset = AVAsset(URL: sourceURL)
        let duration = CMTimeGetSeconds(asset.duration)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        let time = CMTime(seconds: duration/4, preferredTimescale: 1)
        do {
            let imageRef = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
            return UIImage(CGImage: imageRef)
        } catch {
            print(error)
            return UIImage()
        }
    }
    
    private func getDuration(sourceURL: NSURL) -> String {
        let asset = AVAsset(URL: sourceURL)
        let durationInSeconds = CMTimeGetSeconds(asset.duration)
        
        let seconds = Int(durationInSeconds % 60)
        let totalMinutes = Int(durationInSeconds / 60)
        let minutes = Int(Double(totalMinutes) % 60)
        let hours = Int(Double(totalMinutes) / 60)
        
        if hours <= 0 {
            return String(format: "%02d:%02d", minutes, seconds)
        } else {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
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
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.VideoCellIdentifier, forIndexPath: indexPath) as! VideoTableViewCell
        let video = videos[indexPath.row]
        
        cell.titleLabel.text = video.lastPathComponent
        cell.durationLabel.text = getDuration(video)
        cell.thumbnail.image = nil
        cell.thumbnail.image = getVideoThumbnail(video)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            videos.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    
    /*
     // Override to support rearranging the table view.
     override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
     
     }
     */
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Storyboard.PlayVideoSegue {
            
            let playerController = segue.destinationViewController as! PlayerViewController
            
            if let selectedMealCell = sender as? VideoTableViewCell {
                let indexPath = tableView.indexPathForCell(selectedMealCell)!
                let video = videos[indexPath.row]
                let player = AVPlayer(URL: video)
                playerController.player = player
                player.play()
            }
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
}
