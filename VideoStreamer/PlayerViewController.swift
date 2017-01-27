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
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayerForVideo()
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerItem!.removeObserver(self, forKeyPath: "status")
        player!.removeObserver(self, forKeyPath: "rate")
        if defaults.bool(forKey: SettingsConstants.ResumePlayback) {
            video?.lastPlayedTime = player?.currentTime()
            
            // TODO: Save videos with new lastPlayedTime
        } else {
            video?.lastPlayedTime = nil
        }
    }
    
    fileprivate func setupPlayerForVideo() {
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destination = documentsDirectoryURL.appendingPathComponent((video?.filename)!)

        // If video not downloaded, stream from url
        if !FileManager.default.fileExists(atPath: destination.path) {
            playerItem = AVPlayerItem(url: video!.url as URL)
        } else {
            playerItem = AVPlayerItem(url: destination)
        }
        
        player = AVPlayer(playerItem: playerItem!)
        
        if defaults.bool(forKey: SettingsConstants.ResumePlayback) {
            if let time = video?.lastPlayedTime  {
                player!.seek(to: time)
            }
        }
        playerItem!.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        player!.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
    }
    
    fileprivate func displayPlaybackErrorAlert() {
        let playbackError = UIAlertController(title: "An error occurred loading this video", message: nil, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Close", style: .default, handler: { (action) in
            self.dismiss(animated: true, completion: nil)
        })
        playbackError.addAction(dismissAction)
        
        self.present(playbackError, animated: true, completion: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem {
                if playerItem.status == .readyToPlay {
                    player!.play()
                } else if playerItem.status == .failed {
                    displayPlaybackErrorAlert()
                }
            }
        } else if keyPath == "rate" {
            if let player = object as? AVPlayer {
                let userRate = defaults.float(forKey: SettingsConstants.Speed)
                if player.rate != 0 && player.rate != userRate  {
                    player.rate = userRate
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
