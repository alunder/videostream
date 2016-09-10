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
    
    fileprivate func updateUI()
    {
        // Reset any existing data
        thumbnail.image = nil
        titleLabel.text = nil
        durationLabel.text = nil
        
        // Load video data
        if let video = self.video
        {
            if video.filename.isEmpty {
                titleLabel.text = "\(video.url)"
            } else {
                titleLabel.text = video.filename
            }
            
            imageLoadingIndicator.startAnimating()
            DispatchQueue.global(qos: .utility).async {
                let asset = AVAsset(url: video.url as URL)
                let durationInSeconds = CMTimeGetSeconds(asset.duration)
                
                // If video file has title metadata set titleLabel to it, otherwise keep filename
                let titles = AVMetadataItem.metadataItems(from: asset.commonMetadata,
                                                          withKey: AVMetadataCommonKeyTitle,
                                                          keySpace: AVMetadataKeySpaceCommon)
                if !titles.isEmpty {
                    if let title = titles.first?.value {
                        DispatchQueue.main.async {
                            self.titleLabel.text = title as? String
                        }
                    }
                }
                
                if durationInSeconds.isFinite {
                    // Format duration into readable time
                    let seconds = Int(durationInSeconds.truncatingRemainder(dividingBy: 60))
                    let totalMinutes = Int(durationInSeconds / 60)
                    let minutes = Int(Double(totalMinutes).truncatingRemainder(dividingBy: 60))
                    let hours = Int(Double(totalMinutes) / 60)
                    
                    //  Set duration label
                    DispatchQueue.main.async {
                        if hours <= 0 {
                            self.durationLabel.text = String(format: "%02d:%02d", minutes, seconds)
                        } else {
                            self.durationLabel.text = String(format: "%d:%02d:%02d", hours, minutes, seconds)
                        }
                    }
                    
                    // Load thumbnail image
                    let imagePath = (UIApplication.shared.delegate as! AppDelegate).imagesDirectoryPath + "/\(video.filename).png"
                    // Check if thumbnail already exists
                    if FileManager.default.fileExists(atPath: imagePath) {
                        let data = FileManager.default.contents(atPath: imagePath)
                        let image = UIImage(data: data!)
                        DispatchQueue.main.async {
                            self.thumbnail.image = image
                            self.imageLoadingIndicator.stopAnimating()
                        }
                    } else {
                        // Generate image
                        let imageGenerator = AVAssetImageGenerator(asset: asset)
                        let time = CMTime(seconds: durationInSeconds/4, preferredTimescale: 600)
                        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { (_, imageRef, _, _, error) in
                            
                            if let imageCG = imageRef {
                                let image = UIImage(cgImage: imageCG)
                                DispatchQueue.main.async {
                                    self.thumbnail.image = image
                                    self.imageLoadingIndicator.stopAnimating()
                                }
                                
                                // Save thumbnail to Document directory
                                let imageData = UIImagePNGRepresentation(image)
                                let _ = FileManager.default.createFile(atPath: imagePath, contents: imageData, attributes: nil)
                                print("Saved \(imagePath)")

                            } else {
                                DispatchQueue.main.async {
                                    print("Failed to load thumbnail for \(video.filename)")
                                    print(error, "\n")
                                    self.thumbnail.image = UIImage(named: "Generic Video")!
                                    self.imageLoadingIndicator.stopAnimating()
                                }
                            }
                        }
                    }
                    
                } else {
                    DispatchQueue.main.async {
                        self.durationLabel.text = "Live Broadcast"
                        self.thumbnail.image = UIImage(named: "Broadcast")
                        self.imageLoadingIndicator.stopAnimating()
                    }
                }
            }
        }
    }
}
