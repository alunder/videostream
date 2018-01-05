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
}
