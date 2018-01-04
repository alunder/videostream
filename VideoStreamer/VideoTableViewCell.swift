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
import SDWebImage

enum DownloadState {
    case notDownloaded, inProgress, paused, downloaded, disabled
}

class VideoTableViewCell: UITableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var videoDownloadProgressView: UIProgressView!
    
    var videoInfo = [String: String]() // For segue to info view controller
    var video: Video? {
        didSet { updateUI() }
    }
    var downloadState: DownloadState = .notDownloaded {
        didSet {
            switch downloadState {
            case .notDownloaded:
                downloadButton.setTitle("⇩", for: .normal)
                downloadButton.isEnabled = true
            case .inProgress:
                downloadButton.setTitle("✕", for: .normal)
                downloadButton.isEnabled = true
            case .paused:
                break // not implemented
            case .downloaded:
                downloadButton.setTitle("✓", for: .normal)
                downloadButton.isEnabled = false
            case .disabled:
                downloadButton.isHidden = true
            }
        }
    }
    var downloadTask: DownloadTask?
    
    fileprivate func updateUI() {
        // Reset any existing data
        thumbnail.image = nil
        titleLabel.text = nil
        durationLabel.text = "00:00"
        downloadState = .notDownloaded
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
        // TODO: savedfilename is different for youtube: getIdentifier + .mp4
        
        let destination = Video.documentsDirectory.appendingPathComponent(savedFilename)
        
        if !FileManager.default.fileExists(atPath: destination.path) {
            switch downloadState {
            case .notDownloaded:
                downloadState = .inProgress
                durationLabel.isHidden = true
                videoDownloadProgressView.isHidden = false
                
                let request = URLRequest(url: video.url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
                downloadTask = DownloadService.shared.download(request: request)
                downloadTask?.completionHandler = { [weak self] in
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
                                self?.downloadState = .downloaded
                                let alert = UIAlertController(title: "Download successful!", message: "\"\(video.filename)\" is now available offline", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                            }
                        } catch let error {
                            self?.downloadState = .notDownloaded
                            print(error)
                        }
                    }
                }
                downloadTask?.progressHandler = { [weak self] in
                    self?.videoDownloadProgressView.progress = Float($0)
                }
                
                videoDownloadProgressView.progress = 0
                downloadTask?.resume()
            case .inProgress:
                downloadState = .notDownloaded
                self.durationLabel.isHidden = false
                self.videoDownloadProgressView.isHidden = true
                downloadTask?.cancel()
            default:
                break
            }
        } else {
            downloadState = .downloaded
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
        
        // Check if file download exists
        if FileManager.default.fileExists(atPath: destination.path) || video.filename.range(of: ".m3u8") != nil {
            downloadState = .downloaded
        }
        
        imageLoadingIndicator.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = self.downloadState == .downloaded ? AVAsset(url: destination) : AVAsset(url: video.url)
            if !asset.isPlayable {
                if self.downloadState != .downloaded {
                    DispatchQueue.main.async {
                        self.downloadState = .disabled
                    }
                }
            }
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
                                    print(error!.localizedDescription)
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
                    self.downloadState = .disabled
                }
            }
            self.updateVideoDict()
        }
    }
    
    func loadYouTubeData(video: Video) {
        self.imageLoadingIndicator.startAnimating()
        // TODO: Use stored title and save thumbnail
        // TODO: Reenable download check
        //                let savedFilename = video.identifier + ".mp4"
        //                let destination = Video.documentsDirectory.appendingPathComponent(savedFilename)
        //
        //                // Check if file download exists
        //                if FileManager.default.fileExists(atPath: destination.path) {
        //                    self.downloadState = .downloaded
        //                }
        //
        // TODO: add this in else statement when checking with download
        XCDYouTubeClient.default().getVideoWithIdentifier(video.getYouTubeVideoIdentifier()) { (video, error) in
            DispatchQueue.main.async {
                guard let video = video else {
                    self.imageLoadingIndicator.stopAnimating()
                    self.titleLabel.text = "Untitled Video"
                    self.thumbnail.image = UIImage(named: "Generic Video")
                    self.downloadState = .disabled
                    return
                }
                self.titleLabel.text = video.title
                
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
                        self.downloadState = .disabled
                    }
                }
                
                // Load thumbnail image
                let thumbnailURL = URL(string: "https://i.ytimg.com/vi/\(video.identifier)/maxresdefault.jpg") ?? video.smallThumbnailURL
                self.thumbnail.sd_setImage(with: thumbnailURL, placeholderImage: UIImage(named: "Generic Video"), completed: { (image, error, cacheType, url) in
                    DispatchQueue.main.async {
                        self.imageLoadingIndicator.stopAnimating()
                    }
                })
                self.updateVideoDict()
            }
        }
    }
    
    func fileFormatInFilename(_ filename: String) -> Bool {
        for format in Video.validFormats {
            if filename.contains(format) { return true }
        }
        return false
    }
    
    func updateVideoDict() {
        DispatchQueue.main.async {
            self.videoInfo[VideoInfoKeys.Title] = self.titleLabel.text
            self.videoInfo[VideoInfoKeys.Duration] = self.durationLabel.text
            self.videoInfo[VideoInfoKeys.URL] = self.video?.url.absoluteString
            self.videoInfo[VideoInfoKeys.Filename] = self.video?.filename
        }
    }
    
}

