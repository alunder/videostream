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
    
    var url: NSURL
    var title: String
    var isDownloaded: Bool
    
    init?(url: NSURL) {
        self.url = url
        self.title = url.lastPathComponent!
        self.isDownloaded = false
        
        super.init()
        
        // Fails to create video if URL is invalid
        if !isValidURL(url) {
            return nil
        }
    }
    
    private func isValidURL(url: NSURL) -> Bool {
//        if UIApplication.sharedApplication().canOpenURL(url) {
//            return true
//        }
//        return false
        return true
    }
}