//
//  Video.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/27/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import Foundation
import AVFoundation

class Video: NSObject, NSCoding {
    
    var url: URL
    var filename: String
    var lastPlayedTime: CMTime?
    var isYouTube: Bool
    
    // Set later in tableView
    var title: String?
    var durationInSeconds: Float64?
    
    static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let archiveURL = documentsDirectory.appendingPathComponent("videos")
    static let validFormats = [".mp3", ".mp4", ".m3u8", ".avi", ".3gp"]
    
    struct PropertyKey {
        static let urlKey = "url"
        static let lastPlayedKey = "lastPlayedTime"
        static let isYouTube = "isYouTube"
        static let title = "title"
        static let duration = "duration"
    }
    
    init(url: URL, lastPlayedTime: CMTime?) {
        self.url = url
        self.filename = url.lastPathComponent
        self.lastPlayedTime = lastPlayedTime
        self.isYouTube = url.host!.contains("youtube") || url.host!.contains("youtu.be")
        super.init()
    }
    
    init(url: URL, lastPlayedTime: CMTime?, title: String?, duration: Float64?) {
        self.url = url
        self.filename = url.lastPathComponent
        self.lastPlayedTime = lastPlayedTime
        self.isYouTube = url.host!.contains("youtube") || url.host!.contains("youtu.be")
        self.title = title
        self.durationInSeconds = duration
        super.init()
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(url, forKey: PropertyKey.urlKey)
        aCoder.encode(lastPlayedTime, forKey: PropertyKey.lastPlayedKey)
        aCoder.encode(title, forKey: PropertyKey.title)
        aCoder.encode(durationInSeconds, forKey: PropertyKey.duration)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        let url = aDecoder.decodeObject(forKey: PropertyKey.urlKey) as! URL
        let lastPlayedTime = aDecoder.decodeObject(forKey: PropertyKey.lastPlayedKey) as? CMTime
        let title = aDecoder.decodeObject(forKey: PropertyKey.title) as? String
        let duration = aDecoder.decodeObject(forKey: PropertyKey.duration) as? Float64
        
        // Must call designated initializer.
        self.init(url: url, lastPlayedTime: lastPlayedTime, title: title, duration: duration)
    }
    
    func getYouTubeID() -> String {
        if !isYouTube { return "" }
        if url.host!.contains("youtu.be") {
            var identifier = url.path
            identifier.removeFirst()
            return identifier
        } else {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            let identifier = components.queryItems?.first(where: { $0.name == "v" })?.value
            return identifier!
        }
    }
    
    func getFilePath() -> URL {
        var savedFilename = isYouTube ? getYouTubeID() : filename
        if !fileFormatInFilename(savedFilename) {
            savedFilename += ".mp4"
        }
        print(Video.documentsDirectory.appendingPathComponent(savedFilename))
        return Video.documentsDirectory.appendingPathComponent(savedFilename)
    }
    
    private func fileFormatInFilename(_ filename: String) -> Bool {
        for format in Video.validFormats {
            if filename.contains(format) { return true }
        }
        return false
    }
    
    func getThumbnailPath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let cachesDirectoryPath = paths[0] as String
        let imagesDirectoryPath = cachesDirectoryPath + "/Thumbnails"
        
        if self.isYouTube {
            return imagesDirectoryPath + "/\(self.getYouTubeID()).jpg"
        } else {
            return imagesDirectoryPath + "/\(self.filename).png"
        }
    }
}
