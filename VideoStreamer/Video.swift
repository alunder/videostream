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
    
    static let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let archiveURL = documentsDirectory.appendingPathComponent("videos")
    
    struct PropertyKey {
        static let urlKey = "url"
        static let lastPlayedKey = "lastPlayedTime"
    }
    
    init(url: URL, lastPlayedTime: CMTime?) {
        self.url = url
        self.filename = url.lastPathComponent
        self.lastPlayedTime = lastPlayedTime
        super.init()
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(url, forKey: PropertyKey.urlKey)
        aCoder.encode(lastPlayedTime, forKey: PropertyKey.lastPlayedKey)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        let url = aDecoder.decodeObject(forKey: PropertyKey.urlKey) as! URL
        let lastPlayedTime = aDecoder.decodeObject(forKey: PropertyKey.lastPlayedKey) as? CMTime
        
        // Must call designated initializer.
        self.init(url: url, lastPlayedTime: lastPlayedTime)
    }
    
}
