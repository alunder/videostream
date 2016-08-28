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
            titleLabel.text = video.filename
            
            imageLoadingIndicator.startAnimating()
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)) {
                let asset = AVAsset(URL: video.url)
                let durationInSeconds = CMTimeGetSeconds(asset.duration)
                
                // If video file has title metadata set titleLabel to it, otherwise keep filename
                let titles = AVMetadataItem.metadataItemsFromArray(asset.commonMetadata,
                                                                   withKey: AVMetadataCommonKeyTitle,
                                                                   keySpace: AVMetadataKeySpaceCommon)
                if !titles.isEmpty {
                    if let title = titles.first?.value {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.titleLabel.text = title as? String
                        }
                    }
                }
                
                // Format duration into readable time
                let seconds = Int(durationInSeconds % 60)
                let totalMinutes = Int(durationInSeconds / 60)
                let minutes = Int(Double(totalMinutes) % 60)
                let hours = Int(Double(totalMinutes) / 60)
                
                //  Set duration label
                dispatch_async(dispatch_get_main_queue()) {
                    if hours <= 0 {
                        self.durationLabel.text = String(format: "%02d:%02d", minutes, seconds)
                    } else {
                        self.durationLabel.text = String(format: "%d:%02d:%02d", hours, minutes, seconds)
                    }
                }

                // Load thumbnail image
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                let time = CMTime(seconds: durationInSeconds/4, preferredTimescale: 1)
                do {
                    let imageRef = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.thumbnail.image = UIImage(CGImage: imageRef)
                        self.imageLoadingIndicator.stopAnimating()
                    }
                } catch {
                    print("Failed to load thumbnail")
                    print(error)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.thumbnail.image = UIImage(named: "Generic Video")!
                        self.imageLoadingIndicator.stopAnimating()
                    }
                }

            }
            
            // Shows all metadata information
            // for item in assets.commonMetadata {
            // print(item.commonKey!, ":", item.value!)
            // }
            
        }
        
    }
    
}
