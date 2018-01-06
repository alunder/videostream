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

class PlayerViewController: AVPlayerViewController {
    
    var video: Video?
    let defaults = UserDefaults.standard
    var rateToken: NSKeyValueObservation?
    var statusToken: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayerForVideo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let player = player {
            if defaults.bool(forKey: SettingsConstants.ResumePlayback) {
                video?.lastPlayedTime = player.currentTime()
            } else {
                video?.lastPlayedTime = nil
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
    }
    
    func setupPlayerForVideo() {
        guard let video = video else {
            displayPlaybackErrorAlert()
            return
        }
        
        if video.isYouTube {
            playYouTubeVideo(video)
        } else {
            playVideo(video)
        }
    }
    
    func playYouTubeVideo(_ video: Video) {
        if FileManager.default.fileExists(atPath: video.getFilePath().path) {
            configurePlayer(withURL: video.getFilePath())
            return
        }
        
        let identifier = video.getYouTubeID()
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
    
    func playVideo(_ video: Video) {
        // If video not downloaded, stream from url
        if !FileManager.default.fileExists(atPath: video.getFilePath().path) {
            configurePlayer(withURL: video.url)
        } else {
            configurePlayer(withURL: video.getFilePath())
        }
    }
    
    func configurePlayer(withURL url: URL) {
        DispatchQueue.main.async {
            let playerItem = AVPlayerItem(url: url)
//            self.statusToken = playerItem.observe(\.status, options: .new, changeHandler: { (playerItem, change) in
//                if playerItem.status == .readyToPlay {
//                    self.player?.play()
//                } else {
//                    self.displayPlaybackErrorAlert()
//                }
//            })
//
            self.player = AVPlayer(playerItem: playerItem)
            self.rateToken = self.player?.observe(\.rate, options: [.old, .new], changeHandler: { (player, change) in
                print("RATE old: \(change.oldValue!), new: \(change.newValue!)")
                let userRate = self.defaults.float(forKey: SettingsConstants.Speed)
                if change.oldValue == 0.0 && change.newValue != userRate {
                    player.rate = userRate
                }
            })
            self.statusToken = self.player?.observe(\.status, options: .new, changeHandler: { (playerItem, change) in
                if playerItem.status == .readyToPlay {
                    self.player?.play()
                } else {
                    self.displayPlaybackErrorAlert()
                }
            })
            
            if self.defaults.bool(forKey: SettingsConstants.ResumePlayback) {
                if let time = self.video?.lastPlayedTime  {
                    self.player?.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
                }
            }
        }
    }
    
    func displayPlaybackErrorAlert() {
        let playbackError = UIAlertController(title: "An error occurred loading this video", message: nil, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Close", style: .default, handler: { (action) in
            self.dismiss(animated: true, completion: nil)
        })
        playbackError.addAction(dismissAction)
        
        self.present(playbackError, animated: true, completion: nil)
    }
}

