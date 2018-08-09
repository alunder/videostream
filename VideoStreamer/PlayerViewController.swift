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
    var rateToken: NSKeyValueObservation?
    var statusToken: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayerForVideo()
        addLongPressMenu()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let player = player {
            video?.lastPlayedTime = SettingsManager.shared.resumePlayback ? player.currentTime() : nil
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
            self.player = AVPlayer(playerItem: playerItem)
            self.rateToken = self.player?.observe(\.rate, options: [.old, .new], changeHandler: { (player, change) in
                print("RATE old: \(change.oldValue!), new: \(change.newValue!)")
                let userRate = SettingsManager.shared.playbackSpeed
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
            
            if SettingsManager.shared.resumePlayback {
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
    
    // MARK:- Playback Settings
    
    func addLongPressMenu() {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(openMenu))
        view.addGestureRecognizer(recognizer)
    }

    @objc func openMenu() {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let speedAction = UIAlertAction(title: "Playback Speed", style: .default) { _ in
            let submenu = UIAlertController(title: "Playback Speed", message: nil, preferredStyle: .actionSheet)
            for speed in SettingsConstants.Speeds {
                var actionTitle = "\(speed)"
                if SettingsManager.shared.playbackSpeed == speed {
                    actionTitle += "*"
                }
                submenu.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { _ in
                    SettingsManager.shared.playbackSpeed = speed
                    self.player?.rate = speed
                }))
            }
            submenu.addAction(cancelAction)
            self.present(submenu, animated: true, completion: nil)
        }
        
        menu.addAction(speedAction)
        menu.addAction(cancelAction)
        
        present(menu, animated: true, completion: nil)
    }
    
}

