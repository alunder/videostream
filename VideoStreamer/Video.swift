//
//  Video.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/27/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit
import AVFoundation

class Video: NSObject, NSCoding {
    
    // MARK: Constants
    
    static let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    static let archiveURL = documentsDirectory.appendingPathComponent("videos")
    static let cacheURL = documentsDirectory.appendingPathComponent("videoInfo")
    static let validFormats = [".mp3", ".mp4", ".m3u8", ".avi", ".3gp"]
    
    struct PropertyKey {
        static let url = "url"
        static let lastPlayed = "lastPlayedTime"
        static let title = "title"
        static let duration = "duration"
    }
    
    enum VideoType {
        case broadcast, url, youtube
    }
    
    // MARK: Properties
    
    var url: URL
    var filename: String
    var lastPlayedTime: CMTime?
    var type: VideoType
    var title: String
    var durationInSeconds: Float64?
    
    var genericThumbnailImage: UIImage {
        if filename.contains(".mp3") {
            return UIImage(named: "Generic Audio")!
        } else if self.type == .broadcast {
            return UIImage(named: "Broadcast")!
        } else {
            return UIImage(named: "Generic Video")!
        }
    }
    
    var thumbnailImage: UIImage? {
        if FileManager.default.fileExists(atPath: thumbnailPath.path) {
            let data = FileManager.default.contents(atPath: thumbnailPath.path)
            let image = UIImage(data: data!)!
            return image
        }
        return nil
    }
    
    var filePath: URL {
        get {
            var savedFilename: String
            switch type {
            case .url, .broadcast:
                savedFilename = filename
            case .youtube:
                savedFilename = youtubeID!
            }
            
            if !fileFormatInFilename(savedFilename) {
                savedFilename += ".mp4"
            }
            print(Video.documentsDirectory.appendingPathComponent(savedFilename))
            return Video.documentsDirectory.appendingPathComponent(savedFilename)
        }
    }
    
    var thumbnailPath: URL {
        get {
            let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
            let cachesDirectoryPath = paths[0] as String
            let imagesDirectoryPath = cachesDirectoryPath + "/Thumbnails"
            
            switch type {
            case .url, .broadcast:
                return URL(string: imagesDirectoryPath + "/\(filename).png")!
            case .youtube:
                return URL(string: imagesDirectoryPath + "/\(youtubeID!).jpg")!
            }
        }
    }
    
    var youtubeID: String? {
        get {
            switch type {
            case .url, .broadcast:
                return nil
            case .youtube:
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
        }
    }
    
    var isDownloaded: Bool {
        return FileManager.default.fileExists(atPath: filePath.path)
    }
    
    // MARK: Initializers
    
    init(url: URL, lastPlayedTime: CMTime?, title: String? = nil, duration: Float64? = nil) {
        self.url = url
        self.filename = url.lastPathComponent
        self.lastPlayedTime = lastPlayedTime
        if url.host!.contains("youtube") || url.host!.contains("youtu.be") {
            self.type = .youtube
        } else if filename.contains(".m3u8") {
            self.type = .broadcast
        } else {
            self.type = .url
        }
        self.title = title ?? (url.lastPathComponent.isEmpty ? url.absoluteString : url.lastPathComponent)
        self.durationInSeconds = duration
        super.init()
    }
    
    // MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(url, forKey: PropertyKey.url)
        aCoder.encode(lastPlayedTime, forKey: PropertyKey.lastPlayed)
        aCoder.encode(title, forKey: PropertyKey.title)
        aCoder.encode(durationInSeconds, forKey: PropertyKey.duration)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let url = aDecoder.decodeObject(forKey: PropertyKey.url) as! URL
        let lastPlayedTime = aDecoder.decodeObject(forKey: PropertyKey.lastPlayed) as? CMTime
        let title = aDecoder.decodeObject(forKey: PropertyKey.title) as? String
        let duration = aDecoder.decodeObject(forKey: PropertyKey.duration) as? Float64
        
        // Must call designated initializer.
        self.init(url: url, lastPlayedTime: lastPlayedTime, title: title, duration: duration)
    }
    
    // MARK: Private Functions
    
    private func fileFormatInFilename(_ filename: String) -> Bool {
        for format in Video.validFormats {
            if filename.contains(format) { return true }
        }
        return false
    }
}
