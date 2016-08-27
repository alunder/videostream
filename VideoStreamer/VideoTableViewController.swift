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
        saveVideoFromString("https://rsn-25ge7nek.googlevideo.com/videoplayback?dur=596.567&ei=eU3AV7u9HdXCcPv6lNgD&expire=1472242137&sver=3&sparams=dur,ei,expire,id,initcwndbps,ip,ipbits,ipbypass,itag,lmt,mime,mm,mn,ms,mv,nh,pl,ratebypass,requiressl,source,upn&source=youtube&ratebypass=yes&signature=6A8C6411DDC7C03102848D898D5737FE87F9ACEC.21F4C435B6B848B470BAA928A1A8FDC74083F0EB&upn=gh4-hzxA5q0&itag=22&key=cms1&lmt=1471054390643811&id=o-AEZe8vCawsplP58czKnrqxF6I2-LDz-QTGYIqPtgL5wg&mime=video/mp4&pl=24&ipbits=0&ip=51.255.133.247&requiressl=yes&redirect_counter=1&req_id=11dc3ab8d95ba3ee&cms_redirect=yes&ipbypass=yes&mm=31&mn=sn-25ge7nek&ms=au&mt=1472239151&mv=m&nh=IgpwcjAxLnBhcjEwKg4zNy4xODcuMjMxLjI0MA&&title=Big+Buck+Bunny")
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
        if let videoURL = NSURL(string: urlString) {
            if let video = Video(url: videoURL) {
                self.videos.append(video)
                tableView.reloadData()
            } else {
                let invalidLink = UIAlertController(title: "Invalid URL", message: nil, preferredStyle: .Alert)
                let dismissAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
                invalidLink.addAction(dismissAction)
                
                self.presentViewController(invalidLink, animated: true, completion: nil)
                
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
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Storyboard.PlayVideoSegue {
            if let playerController = segue.destinationViewController as? AVPlayerViewController {
                if let selectedVideoCell = sender as? VideoTableViewCell {
                    let indexPath = tableView.indexPathForCell(selectedVideoCell)!
                    let video = videos[indexPath.row]
                    let player = AVPlayer(URL: video.url)
                    playerController.player = player
                    player.play()
                }
            }
        }
    }
    
}
