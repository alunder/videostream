//
//  Constants.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 1/5/18.
//  Copyright © 2018 Ritam Sarmah. All rights reserved.
//

import Foundation
import XCDYouTubeKit

struct YouTubeVideoQuality {
    static let hd720 = NSNumber(value: XCDYouTubeVideoQuality.HD720.rawValue)
    static let medium360 = NSNumber(value: XCDYouTubeVideoQuality.medium360.rawValue)
    static let small240 = NSNumber(value: XCDYouTubeVideoQuality.small240.rawValue)
}

struct VideoInfoKeys {
    static let Title = "Title"
    static let Duration = "Duration"
    static let URL = "URL"
    static let Filename = "Filename"
    static let Thumbnail = "Thumbnail"
}

struct Storyboard {
    static let VideoCellIdentifier = "VideoCell"
    static let AVPlayerVCSegue = "ShowPlayer"
    static let VideoInfoSegue = "ShowVideoInfo"
    static let PlayerFromInfoSegue = "ShowPlayerFromInfo"
}

struct SettingsConstants {
    static let Speed = "playbackSpeed"
    static let ResumePlayback = "doesResumePlayback"
    static let Speeds: [Float] = [0.25, 0.5, 1.0, 1.25, 1.5, 2.0]
}

struct Colors {
    static let themeColor = UIColor.orange //UIColor(red: 199/255, green: 0/255, blue: 57/255, alpha: 1.0)
//    static let buttonColor = UIColor(red: 0.898, green: 0.898, blue: 0.937, alpha: 1.0)
    static let buttonColor = UIColor(red: 0.91, green: 0.91, blue: 0.91, alpha: 1.0)
    static let progressColor = UIColor(red: 0.824, green: 0.824, blue: 0.863, alpha: 1.0)
}

enum DownloadState {
    case notDownloaded, inProgress, paused, downloaded, disabled
}
