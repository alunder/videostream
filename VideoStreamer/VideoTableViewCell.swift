//
//  VideoTableViewCell.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/25/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

class VideoTableViewCell: UITableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var videoDownloadProgressView: UIProgressView!
    
    var video: Video? {
        didSet {
            updateUI()
        }
    }
    
    fileprivate func updateUI() {
        // Reset any existing data
        thumbnail.image = nil
        titleLabel.text = nil
        durationLabel.text = nil
        downloadButton.isEnabled = true
        videoDownloadProgressView.isHidden = true
        
        // Load video data
        if let video = self.video {
            if video.filename.isEmpty {
                titleLabel.text = "\(video.url)"
            } else {
                titleLabel.text = video.filename
            }
            
            let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destination = documentsDirectoryURL.appendingPathComponent(video.filename)
            
            if FileManager.default.fileExists(atPath: destination.path) {
                downloadButton.isEnabled = false
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
                                    print(error!, "\n")
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
    
    @IBAction func setupAssetDownload(_ sender: UIButton) {
        
        guard let video = video else { return }
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destination = documentsDirectoryURL.appendingPathComponent(video.filename)
        print(destination)
        
        if !FileManager.default.fileExists(atPath: destination.path) {
            downloadButton.isEnabled = false
            durationLabel.isHidden = true
            videoDownloadProgressView.isHidden = false
            
            let request = URLRequest(url: video.url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
            var downloadTask = DownloadService.shared.download(request: request)
            downloadTask.completionHandler = { [weak self] in
                switch $0 {
                case .failure(let error):
                    print(error)
                case .success(let data):
                    print("Number of bytes: \(data.count)")
                    // Save to disk
                    do {
                        try data.write(to: URL(fileURLWithPath: destination.path), options: [.atomic])
                        DispatchQueue.main.async {
                            self?.videoDownloadProgressView.isHidden = true
                            self?.durationLabel.isHidden = false
                            self?.downloadButton.isEnabled = false
                            let alert = UIAlertController(title: "Download successful!", message: "\"\(video.filename)\" is now available offline", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                        }
                    } catch let error {
                        print(error)
                    }
                }
            }
            downloadTask.progressHandler = { [weak self] in
                print("Download progress for \(video.filename): \($0)")
                self?.videoDownloadProgressView.progress = Float($0)
            }
            
            videoDownloadProgressView.progress = 0
            downloadTask.resume()
        } else {
            let downloadAlert = UIAlertController(title: "Video already downloaded!", message: nil, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            downloadAlert.addAction(action)
            
            UIApplication.shared.keyWindow?.rootViewController?.present(downloadAlert, animated: true, completion: nil)
        }
    }
    
}
