//
//  Video.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/27/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import Foundation
import AVFoundation

class Video: NSObject {
    
    var url: URL
    var filename: String
    var isDownloaded: Bool
    
    init(url: URL) {
        self.url = url
        self.filename = url.lastPathComponent
        self.isDownloaded = false
        
        super.init()
    }
}
