//
//  VideoInfoManager.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 1/4/18.
//  Copyright © 2018 Ritam Sarmah. All rights reserved.
//

import Foundation

class VideoInfoManager {
    static let shared = VideoInfoManager()
    
    var videos = [Video]()
    var cache: [URL : [String: Any]] // associate video URL with videoInfo dictionary
    
    private init() {
        self.cache = [URL : [String: Any]]()
        if let savedVideos = loadVideos() {
            videos += savedVideos
        }
    }
    
    func moveVideo(at sourceIndex: Int, to destinationIndex: Int) {
        let movedObject = videos.remove(at: sourceIndex)
        addVideo(movedObject, at: destinationIndex)
    }
    
    func addVideo(_ video: Video, at index: Int) {
        videos.insert(video, at: index)
        saveVideos()
    }
    
    func deleteVideo(at index: Int) {
        let video = videos.remove(at: index)
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
            if let thumbnail = video.thumbnailPath?.path {
                try fileManager.removeItem(atPath: thumbnail)
            }
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
