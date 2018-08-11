//
//  TimeInterval+FormattedString.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/11/18.
//  Copyright © 2018 Ritam Sarmah. All rights reserved.
//

import Foundation

extension TimeInterval {
    func formattedString() -> String {
        let seconds = Int(self.truncatingRemainder(dividingBy: 60))
        let totalMinutes = Int(self / 60)
        let minutes = Int(Double(totalMinutes).truncatingRemainder(dividingBy: 60))
        let hours = Int(Double(totalMinutes) / 60)
        
        if hours <= 0 {
            return String(format: "%02d:%02d", minutes, seconds)
        } else {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
    }
}
