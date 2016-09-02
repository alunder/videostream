//
//  PlayerViewController.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 9/2/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class PlayerViewController: AVPlayerViewController {
    
    var video: Video?
    var playerItem: AVPlayerItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayerForVideo()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        playerItem!.removeObserver(self, forKeyPath: "status")
        player!.removeObserver(self, forKeyPath: "rate")
    }
    
    private func setupPlayerForVideo() {
        playerItem = AVPlayerItem(URL: video!.url)
        player = AVPlayer(playerItem: playerItem!)
        playerItem!.addObserver(self, forKeyPath: "status", options: .New, context: nil)
        player!.addObserver(self, forKeyPath: "rate", options: .New, context: nil)
    }
    
    private func displayPlaybackErrorAlert() {
        let playbackError = UIAlertController(title: "An error occurred loading this video", message: nil, preferredStyle: .Alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .Default, handler: { (action) in
            self.dismissViewControllerAnimated(true, completion: nil)
        })
        playbackError.addAction(dismissAction)
        
        self.presentViewController(playbackError, animated: true, completion: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem {
                if playerItem.status == .ReadyToPlay {
                    player!.play()
                } else if playerItem.status == .Failed {
                    displayPlaybackErrorAlert()
                }
            }
        } else if keyPath == "rate" {
            if let player = object as? AVPlayer {
                let userRate = NSUserDefaults.standardUserDefaults().floatForKey(SettingsConstants.Speed)
                if player.rate != 0 && player.rate != userRate  {
                    player.rate = userRate
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
