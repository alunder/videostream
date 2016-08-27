//
//  VideoTableViewCell.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/25/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit
import AVFoundation

class VideoTableViewCell: UITableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!
    
    var video: Video? {
        didSet {
            updateUI()
        }
    }
    
    private func updateUI()
    {
        // Reset any existing data
        thumbnail.image = nil
        titleLabel.text = nil
        durationLabel.text = nil
        
        // Load video data
        if let video = self.video
        {
            titleLabel?.text = video.title
            
            imageLoadingIndicator.startAnimating()
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
                let asset = AVAsset(URL: video.url)
                let durationInSeconds = CMTimeGetSeconds(asset.duration)
                
                // Format duration into readable time
                let seconds = Int(durationInSeconds % 60)
                let totalMinutes = Int(durationInSeconds / 60)
                let minutes = Int(Double(totalMinutes) % 60)
                let hours = Int(Double(totalMinutes) / 60)
                
                dispatch_async(dispatch_get_main_queue()) {
                    if hours <= 0 {
                        self.durationLabel.text = String(format: "%02d:%02d", minutes, seconds)
                    } else {
                        self.durationLabel.text = String(format: "%d:%02d:%02d", hours, minutes, seconds)
                    }
                }
                
                // Set thumbnail image
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                let time = CMTime(seconds: durationInSeconds/4, preferredTimescale: 1)
                do {
                    let imageRef = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.thumbnail.image = UIImage(CGImage: imageRef)
                        self.imageLoadingIndicator.stopAnimating()
                    }
                } catch {
                    print(error)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.thumbnail.image = UIImage(named: "Generic Video")!
                        self.imageLoadingIndicator.stopAnimating()
                    }
                }
            }
        }
        
    }
    
}
