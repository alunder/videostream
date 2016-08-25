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

class VideoTableViewController: UITableViewController {

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
        let video1 = NSURL(string: "https://r11---sn-n4v7kn7k.googlevideo.com/videoplayback?requiressl=yes&id=68b9781a8f9c6e45&itag=18&source=webdrive&ttl=transient&app=explorer&ip=2601:204:c301:b6bb:70c5:485f:b4ef:546&ipbits=8&expire=1472164620&sparams=expire,id,ip,ipbits,itag,mm,mn,ms,mv,nh,pl,requiressl,source,ttl&signature=65C0A28028CC450468AA3117E9330F320975632A.3547E55630EEF3230AE14837E1288CA7F9DFF5D7&key=cms1&pl=26&sc=yes&cms_redirect=yes&mm=31&mn=sn-n4v7kn7k&ms=au&mt=1472156430&mv=m&nh=IgpwcjAxLnBhbzAzKgkxMjcuMC4wLjE")!
        let video2 = NSURL(string: "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")!
        let video3 = NSURL(string: "https://r15---sn-n4v7kn7y.googlevideo.com/videoplayback?requiressl=yes&id=a728dd436e60cc18&itag=22&source=webdrive&ttl=transient&app=explorer&ip=2601:204:c301:b6bb:70c5:485f:b4ef:546&ipbits=8&expire=1472170210&sparams=expire,id,ip,ipbits,itag,mm,mn,ms,mv,nh,pl,requiressl,source,ttl&signature=4C4344A6CE4B326789281003256856EF65350765.17E4CEDEF78100E6B9D2E9E88BA941408D06FB21&key=cms1&pl=26&sc=yes&cms_redirect=yes&mm=31&mn=sn-n4v7kn7y&ms=au&mt=1472156430&mv=m&nh=IgpwcjA0LnNqYzA3KgkxMjcuMC4wLjE")!
        videos.appendContentsOf([video1, video2, video3])
        
    }
    
    @IBAction func addStream(sender: UIBarButtonItem) {
        let videoLinkAlert = UIAlertController(title: "New Video Stream", message: "Enter video streaming link", preferredStyle: .Alert)
        var linkField: UITextField!
        
        // Set up textField to enter link
        videoLinkAlert.addTextFieldWithConfigurationHandler { (textField) in
            textField.text = "http://"
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
    
    func textChanged(sender: AnyObject) {
        let tf = sender as! UITextField
        var resp: UIResponder = tf
        while !(resp is UIAlertController) { resp = resp.nextResponder()! }
        let alert = resp as? UIAlertController
        (alert!.actions[1] as UIAlertAction).enabled = (tf.text != "")
    }
    
    // TODO: Make run background
    private func downloadVideo(videoURL: String) {
        if let url = NSURL(string: videoURL) {
            if UIApplication.sharedApplication().canOpenURL(url) {
                videos.insert(url, atIndex: 0)
                tableView.reloadData()
                //                let player = AVPlayer(URL: url)
                //                let playerController = AVPlayerViewController()
                //                let testSlider = UISlider()
                //                playerController.player = player
                //                playerController.contentOverlayView?.addSubview(testSlider)
                //                self.presentViewController(playerController, animated: true) {
                //                    player.play()
                //                    player.setRate(1.0, time: kCMTimeInvalid, atHostTime: kCMTimeInvalid)
                //                }
            } else {
                let invalidLink = UIAlertController(title: "Invalid URL!", message: nil, preferredStyle: .Alert)
                let dismissAction = UIAlertAction(title: "Dismiss", style: .Default, handler: nil)
                invalidLink.addAction(dismissAction)
                
                presentViewController(invalidLink, animated: true, completion: nil)
            }
        }
    }
    
    // TODO: Make this run in utility queue
    private func getVideoThumbnail(sourceURL: NSURL) -> UIImage {
        let asset = AVAsset(URL: sourceURL)
        let duration = CMTimeGetSeconds(asset.duration)
        print(duration)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        let time = CMTime(seconds: duration/2, preferredTimescale: 1)
        do {
            let imageRef = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
            return UIImage(CGImage: imageRef)
        } catch {
            print(error)
            return UIImage(named: "\(sourceURL)")!
        }
    }
    
//    private func getDuration(sourceURL: NSURL) -> NSDate {
//        if let asset = AVAsset(URL: sourceURL) {
//            let durationInSeconds = CMTimeGetSeconds(asset.duration)
//
//            let duration = NSDate(timeIntervalSince1970: durationInSeconds)
//            let formatter = NSDateFormatter()
//            formatter.dateFormat = "HH:mm:ss"
//            
//            return formatter.
//        }
//    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.VideoCellIdentifier, forIndexPath: indexPath) as! VideoTableViewCell
        let video = videos[indexPath.row]
        
        // FIXME: Get title for mp4 file instead of using url name
        cell.titleLabel.text = "\(video)"
        cell.thumbnail.image = getVideoThumbnail(video)
        cell.durationLabel.text = "1:44"

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
