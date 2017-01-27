//
//  VideoData.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 9/13/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import Foundation

class VideoData: NSObject {
    
    var videos = [Video]()
    
    func saveVideo(from url: URL) -> Bool {
        let video = Video(url: url, lastPlayedTime: nil)
        videos.insert(video, at: 0)
        return saveVideos()
    }

    // MARK: NSCoding
    func saveVideos() -> Bool {
        return NSKeyedArchiver.archiveRootObject(videos, toFile: Video.archiveURL.path)
    }
    
    func loadVideos() {
        guard let videos = NSKeyedUnarchiver.unarchiveObject(withFile: Video.archiveURL.path) as? [Video] else { return }
        self.videos = videos
    }

}

// Singleton to manage video data
class SharedVideoData {
    
    static let sharedInstance = VideoData()
    private init() {}
    
}
