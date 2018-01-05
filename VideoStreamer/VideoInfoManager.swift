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
    
    var cache: [URL : [String: Any]] // associate video URL with videoInfo dictionary
    
    private init() {
        self.cache = [URL : [String: Any]]()
    }
    
    
}
