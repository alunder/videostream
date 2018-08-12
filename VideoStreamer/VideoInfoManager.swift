//
//  VideoInfoManager.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 1/4/18.
//  Copyright © 2018 Ritam Sarmah. All rights reserved.
//

import Foundation
import XCDYouTubeKit
import SDWebImage

class VideoInfo: NSObject, NSCoding {
    let title: String
    let duration: String
    let filename: String
    let url: URL
    let thumbnailUrl: URL?
    
    struct PropertyKey {
        static let title = "title"
        static let duration = "duration"
        static let filename = "filename"
        static let url = "url"
        static let thumbnailUrl = "thumbnail"
    }
    
    init(title: String, duration: String, filename: String, url: URL, thumbnailUrl: URL?) {
        self.title = title
        self.duration = duration
        self.filename = filename
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        
        super.init()
    }
    
    init(video: Video) {
        self.title = video.title
        self.duration = video.durationInSeconds?.formattedString() ?? "--:--"
        self.filename = video.filename
        self.url = video.url
        self.thumbnailUrl = video.thumbnailPath
        
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: PropertyKey.title)
        aCoder.encode(duration, forKey: PropertyKey.duration)
        aCoder.encode(filename, forKey: PropertyKey.filename)
        aCoder.encode(url, forKey: PropertyKey.url)
        aCoder.encode(thumbnailUrl, forKey: PropertyKey.thumbnailUrl)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let title = aDecoder.decodeObject(forKey: PropertyKey.title) as! String
        let duration = aDecoder.decodeObject(forKey: PropertyKey.duration) as! String
        let filename = aDecoder.decodeObject(forKey: PropertyKey.filename) as! String
        let url = aDecoder.decodeObject(forKey: PropertyKey.url) as! URL
        let thumbnailUrl = aDecoder.decodeObject(forKey: PropertyKey.thumbnailUrl) as? URL
        
        // Must call designated initializer.
        self.init(title: title, duration: duration, filename: filename, url: url, thumbnailUrl: thumbnailUrl)
    }
}

enum VideoError: Error {
    case videoAlreadyExists
}

// Set to class functions

class VideoInfoManager {
    static let shared = VideoInfoManager()
    
    var videos = [Video]()
    private var cache = [URL : VideoInfo]() // Associate video URL with VideoInfo for offline access
    
    private init() {
        if let savedCache = loadCache() {
            cache = savedCache
        }
        if let savedVideos = loadVideos() {
            videos += savedVideos
        }
    }
    
    // MARK: - Video Info
    
    func getInfo(for video: Video) -> VideoInfo? {
        return cache[video.url]
    }
    
    func updateInfo(for video: Video, with videoInfo: VideoInfo? = nil) -> VideoInfo {
        cache[video.url] = videoInfo ?? VideoInfo(video: video)
        saveVideos()
        return cache[video.url]!
    }
    
    // MARK: - Video Management
    
    func moveVideo(at sourceIndex: Int, to destinationIndex: Int) {
        let movedObject = videos.remove(at: sourceIndex)
        try! addVideo(movedObject, at: destinationIndex)
    }
    
    func addVideo(_ video: Video, at index: Int) throws {
        if cache[video.url] != nil {
            throw VideoError.videoAlreadyExists
        }
        videos.insert(video, at: index)
        saveVideos()
    }
    
    func deleteVideo(at index: Int) {
        let video = videos.remove(at: index)
        cache.removeValue(forKey: video.url)
        deleteDownload(forVideo: video)
        deleteThumbnail(forVideo: video)
        
        // Cancel potential download
        if let task = DownloadService.shared.getDownloads(withId: video.url.absoluteString)?.first {
            task.cancel()
        }
        saveVideos()
    }
    
    func resetCache() {
        cache = [URL : VideoInfo]()
        for video in videos {
            deleteThumbnail(forVideo: video)
        }
        saveVideos()
    }
    
    func deleteThumbnail(forVideo video: Video) {
        do {
            try FileManager.default.removeItem(atPath: video.thumbnailPath.path)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func deleteAllDownloads() {
        for video in videos {
            deleteDownload(forVideo: video)
        }
    }
    
    func deleteDownload(forVideo video: Video) {
        do {
            try FileManager.default.removeItem(at: video.filePath)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func saveVideos() {
        let videoSaveSuccess = NSKeyedArchiver.archiveRootObject(videos, toFile: Video.archiveURL.path)
        let cacheSaveSuccess = NSKeyedArchiver.archiveRootObject(cache, toFile: Video.cacheURL.path)
        if !videoSaveSuccess || !cacheSaveSuccess {
            print("Failed to save videos")
        }
    }
    
    func loadVideos() -> [Video]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Video.archiveURL.path) as? [Video]
    }
    
    func loadCache() -> [URL : VideoInfo]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Video.cacheURL.path) as? [URL : VideoInfo]
    }
    
    //    func loadSampleVideos() {
    //        saveVideoFromString("http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4")
    //        saveVideoFromString("http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_1mb.mp4")
    //        saveVideoFromString("http://techslides.com/demos/sample-videos/small.mp4")
    //    }
    
}
