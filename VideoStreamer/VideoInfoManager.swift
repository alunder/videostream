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

struct VideoInfo {
    let title: String
    let duration: String
    let filename: String
    let url: URL
    let thumbnailUrl: URL?
}

extension VideoInfo {
    init(video: Video) {
        self.title = video.title
        self.duration = video.durationInSeconds?.formattedString() ?? "00:00"
        self.filename = video.filename
        self.url = video.url
        self.thumbnailUrl = video.thumbnailPath
    }
}

enum VideoError: Error {
    case videoAlreadyExists
}

// Set to class functions

class VideoInfoManager {
    static let shared = VideoInfoManager()
    
    var videos = [Video]()
    private var cache: [URL : VideoInfo] // Associate video URL with VideoInfo for offline access
    
    private init() {
        self.cache = [URL : VideoInfo]()
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
    
    func deleteThumbnail(forVideo video: Video) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: video.thumbnailPath.path)
        } catch {
            print(error.localizedDescription)
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
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(videos, toFile: Video.archiveURL.path)
        if !isSuccessfulSave {
            print("Failed to save videos")
        }
    }
    
    func loadVideos() -> [Video]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Video.archiveURL.path) as? [Video]
    }
    
    //    func loadSampleVideos() {
    //        saveVideoFromString("http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4")
    //        saveVideoFromString("http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_1mb.mp4")
    //        saveVideoFromString("http://techslides.com/demos/sample-videos/small.mp4")
    //    }
    
}
