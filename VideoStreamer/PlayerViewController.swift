//
//  PlayerViewController.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 9/2/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit
import AVKit
import XCDYouTubeKit

struct YouTubeVideoQuality {
    static let hd720 = NSNumber(value: XCDYouTubeVideoQuality.HD720.rawValue)
    static let medium360 = NSNumber(value: XCDYouTubeVideoQuality.medium360.rawValue)
    static let small240 = NSNumber(value: XCDYouTubeVideoQuality.small240.rawValue)
}

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
        if defaults.bool(forKey: SettingsConstants.ResumePlayback) {
            video?.lastPlayedTime = player?.currentTime()
        } else {
            video?.lastPlayedTime = nil
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func setupPlayerForVideo() {
        guard let video = video else {
            displayPlaybackErrorAlert()
            return
        }
        
        if video.isYouTube {
            playYouTubeVideo()
        } else {
            playVideo()
            
        }
    }
    
    func playYouTubeVideo() {
        
        // TODO check for downloaded video
        
        let identifier = video!.getYouTubeVideoIdentifier()
        XCDYouTubeClient.default().getVideoWithIdentifier(identifier) { (video, error) in
            if let streamURLs = video?.streamURLs, let streamURL = (streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?? streamURLs[YouTubeVideoQuality.hd720] ?? streamURLs[YouTubeVideoQuality.medium360] ?? streamURLs[YouTubeVideoQuality.small240]) {
                self.configurePlayer(withURL: streamURL)
            } else {
                DispatchQueue.main.async {
                    self.displayPlaybackErrorAlert()
                }
            }
        }
    }
    
    func playVideo() {
        let destination = Video.documentsDirectory.appendingPathComponent(video!.filename)
        
        // If video not downloaded, stream from url
        if !FileManager.default.fileExists(atPath: destination.path) {
            configurePlayer(withURL: video!.url)
        } else {
            configurePlayer(withURL: destination)
        }
    }
    
    func configurePlayer(withURL url: URL) {
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem!)
        
        if defaults.bool(forKey: SettingsConstants.ResumePlayback) {
            if let time = self.video!.lastPlayedTime  {
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

