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
import XCDYouTubeKit

class VideoTableViewCell: UITableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var videoDownloadProgressView: UIProgressView!
    
    var video: Video? {
        didSet { updateUI() }
    }
    
    fileprivate func updateUI() {
        // Reset any existing data
        thumbnail.image = nil
        titleLabel.text = nil
        durationLabel.text = nil
        downloadButton.isEnabled = true
        videoDownloadProgressView.isHidden = true
        
        // Load video data
        guard let video = self.video else { return }
        if video.isYouTube {
            loadYouTubeData(video: video)
        } else {
            loadVideoData(video: video)
        }
    }
    
    @IBAction func setupAssetDownload(_ sender: UIButton) {
        guard let video = video else { return }
        
        // Validate file format
        var savedFilename = video.filename
        if !fileFormatInFilename(savedFilename) {
            savedFilename += ".mp4"
        }
        
        let destination = Video.documentsDirectory.appendingPathComponent(savedFilename)
        
        if !FileManager.default.fileExists(atPath: destination.path) {
            downloadButton.isEnabled = false
            durationLabel.isHidden = true
            videoDownloadProgressView.isHidden = false
            
            let request = URLRequest(url: video.url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
            var downloadTask = DownloadService.shared.download(request: request)
            downloadTask.completionHandler = { [weak self] in
                switch $0 {
                case .failure(let error):
                    print(error.localizedDescription)
                case .success(let data):
                    print("Number of bytes: \(data.count)")
                    // Save to disk
                    do {
                        try data.write(to: URL(fileURLWithPath: destination.path), options: [.atomic])
                        DispatchQueue.main.async {
                            self?.videoDownloadProgressView.isHidden = true
                            self?.durationLabel.isHidden = false
                            self?.downloadButton.isEnabled = false
                            self?.downloadButton.setTitle("✓", for: .normal)
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
    
    func loadVideoData(video: Video) {
        titleLabel.text = video.filename.isEmpty ? "\(video.url)" : video.filename
        var savedFilename = video.filename
        if !fileFormatInFilename(savedFilename) {
            savedFilename += ".mp4"
        }
        
        let destination = Video.documentsDirectory.appendingPathComponent(savedFilename)
        print(destination)
        
        // Enable downloadButton
        if FileManager.default.fileExists(atPath: destination.path) || video.filename.range(of: ".m3u8") != nil {
            downloadButton.isEnabled = false
            downloadButton.setTitle("✓", for: .normal)
        }
        
        imageLoadingIndicator.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: video.url)
            let durationInSeconds = CMTimeGetSeconds(asset.duration)
            
            // If video file has title metadata set titleLabel to it, otherwise keep filename
            let titles = AVMetadataItem.metadataItems(from: asset.commonMetadata,
                                                      withKey: AVMetadataKey.commonKeyTitle,
                                                      keySpace: AVMetadataKeySpace.common)
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
                DispatchQueue.main.async {
                    let imagePath = (UIApplication.shared.delegate as! AppDelegate).imagesDirectoryPath + "/\(video.filename).png"
                    
                    // Check if thumbnail already exists
                    if FileManager.default.fileExists(atPath: imagePath) {
                        let data = FileManager.default.contents(atPath: imagePath)
                        let image = UIImage(data: data!)
                        self.thumbnail.image = image
                        self.imageLoadingIndicator.stopAnimating()
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
                                    print(error!.localizedDescription, "\n")
                                    self.thumbnail.image = UIImage(named: "Generic Video")!
                                    self.imageLoadingIndicator.stopAnimating()
                                }
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.durationLabel.text = "Live Broadcast"
                    self.thumbnail.image = UIImage(named: "Broadcast")
                    self.imageLoadingIndicator.stopAnimating()
                    self.downloadButton.isHidden = true // Disable download for streams
                }
            }
        }
    }
    
    func loadYouTubeData(video: Video) {
        print("Loading YouTube vid")
        XCDYouTubeClient.default().getVideoWithIdentifier(video.getYouTubeVideoIdentifier()) { (video, error) in
            DispatchQueue.main.async {
                guard let video = video else { return }
                self.titleLabel.text = video.title
                let savedFilename = video.identifier
                let destination = Video.documentsDirectory.appendingPathComponent(savedFilename)
                
                // Enable downloadButton
                if FileManager.default.fileExists(atPath: destination.path) {
                    self.downloadButton.isEnabled = false
                    self.downloadButton.setTitle("✓", for: .normal)
                }
                
                let durationInSeconds = video.duration
                if durationInSeconds.isFinite {
                    let seconds = Int(durationInSeconds.truncatingRemainder(dividingBy: 60))
                    let totalMinutes = Int(durationInSeconds / 60)
                    let minutes = Int(Double(totalMinutes).truncatingRemainder(dividingBy: 60))
                    let hours = Int(Double(totalMinutes) / 60)
                    
                    //  Set duration label
                    if hours <= 0 {
                        self.durationLabel.text = String(format: "%02d:%02d", minutes, seconds)
                    } else {
                        self.durationLabel.text = String(format: "%d:%02d:%02d", hours, minutes, seconds)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.durationLabel.text = "Live Broadcast"
                        self.thumbnail.image = UIImage(named: "Broadcast")
                        self.imageLoadingIndicator.stopAnimating()
                        self.downloadButton.isHidden = true // Disable download for streams
                    }
                }
                
                // Load thumbnail image
                self.imageLoadingIndicator.startAnimating()
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let imageData = try Data(contentsOf: video.smallThumbnailURL!)
                        DispatchQueue.main.async {
                            self.thumbnail.image = UIImage(data: imageData)
                            self.imageLoadingIndicator.stopAnimating()
                        }
                    } catch {
                        print(error.localizedDescription)
                        DispatchQueue.main.async {
                            self.thumbnail.image = UIImage(named: "Generic Video")
                            self.imageLoadingIndicator.stopAnimating()
                        }
                    }
                }
            }
        }
    }
    
    func fileFormatInFilename(_ filename: String) -> Bool {
        for format in Video.validFormats {
            if filename.contains(format) { return true }
        }
        return false
    }
    
}

