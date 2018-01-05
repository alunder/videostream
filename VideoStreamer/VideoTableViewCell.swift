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
    
    var videoInfo = [String: Any]() // For segue to info view controller
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
    
    func updateUI() {
        // Reset any existing data
        thumbnail.image = nil
        titleLabel.text = nil
        durationLabel.text = "00:00"
        downloadState = .notDownloaded
        videoDownloadProgressView.isHidden = true
        
        // Load video data
        guard let video = self.video else { return }
        let manager = VideoInfoManager.shared
        
        if let videoInfo = manager.cache[video.url] {
            self.titleLabel.text = videoInfo[VideoInfoKeys.Title] as? String
            self.durationLabel.text = videoInfo[VideoInfoKeys.Duration] as? String
            let imagePath = videoInfo[VideoInfoKeys.Thumbnail] as? String
            if FileManager.default.fileExists(atPath: imagePath!) {
                let data = FileManager.default.contents(atPath: imagePath!)
                let image = UIImage(data: data!)
                self.thumbnail.image = image
            } else {
                self.thumbnail.image = UIImage(named: "Generic Video")
            }
            self.imageLoadingIndicator.stopAnimating()
        } else {
            if video.isYouTube {
                loadYouTubeData(video: video)
            } else {
                loadVideoData(video: video)
            }
        }
    }
    
    @IBAction func setupAssetDownload(_ sender: UIButton) {
        guard let video = video else { return }
        
        let destination = video.getFilePath()
        
        if !FileManager.default.fileExists(atPath: destination.path) {
            switch downloadState {
            case .notDownloaded:
                downloadState = .inProgress
                durationLabel.isHidden = true
                videoDownloadProgressView.isHidden = false
                videoDownloadProgressView.progress = 0
                
                var downloadUrl = video.url
                let dispatchGroup = DispatchGroup()
                if video.isYouTube {
                    dispatchGroup.enter()
                    XCDYouTubeClient.default().getVideoWithIdentifier(video.getYouTubeID()) { (video, error) in
                        if let streamURLs = video?.streamURLs, let streamURL = (streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?? streamURLs[YouTubeVideoQuality.hd720] ?? streamURLs[YouTubeVideoQuality.medium360] ?? streamURLs[YouTubeVideoQuality.small240]) {
                            downloadUrl = streamURL
                        } else {
                            print("Failed to download YouTube video")
                        }
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .global(qos: .background)) {
                    let request = URLRequest(url: downloadUrl, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
                    self.downloadTask = DownloadService.shared.download(request: request)
                    self.downloadTask?.completionHandler = { [weak self] in
                        switch $0 {
                        case .failure(let error):
                            print(error.localizedDescription)
                        case .success(let data):
                            print("Number of bytes: \(data.count)")
                            // Save to disk
                            do {
                                try data.write(to: destination, options: [.atomic])
                                DispatchQueue.main.async {
                                    self?.videoDownloadProgressView.isHidden = true
                                    self?.durationLabel.isHidden = false
                                    self?.downloadState = .downloaded
                                    let alert = UIAlertController(title: "Download successful!", message: "\"\(video.title ?? video.filename)\" is now available offline", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                                }
                            } catch let error {
                                self?.downloadState = .notDownloaded
                                print(error)
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        self.downloadTask?.progressHandler = { [weak self] in
                            self?.videoDownloadProgressView.progress = Float($0)
                        }
                    }
                    self.downloadTask?.resume()
                }
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
        if titleLabel.text == nil {
            titleLabel.text = video.title ?? (video.filename.isEmpty ? video.url.absoluteString : video.filename)
        }
        
        // Check if file download exists
        let destination = video.getFilePath()
        if FileManager.default.fileExists(atPath: destination.path) {
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
            video.durationInSeconds = durationInSeconds
            
            // If video file has title metadata set titleLabel to it
            let titles = AVMetadataItem.metadataItems(from: asset.commonMetadata,
                                                      withKey: AVMetadataKey.commonKeyTitle,
                                                      keySpace: AVMetadataKeySpace.common)
            if !titles.isEmpty {
                if let title = titles.first?.value {
                    DispatchQueue.main.async {
                        self.titleLabel.text = title as? String
                    }
                    video.title = title as? String
                }
            }
            
            if durationInSeconds.isFinite {
                DispatchQueue.main.async {
                    self.durationLabel.text = self.getStringFrom(durationInSeconds: durationInSeconds)
                    
                    // Load thumbnail image
                    let imagePath = video.getThumbnailPath()
                    
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
        if FileManager.default.fileExists(atPath: video.getFilePath().path) {
            downloadState = .downloaded
            self.titleLabel.text = video.title
            loadVideoData(video: video)
            return
        }
        
        imageLoadingIndicator.startAnimating()
        XCDYouTubeClient.default().getVideoWithIdentifier(video.getYouTubeID()) { (video, error) in
            DispatchQueue.main.async {
                guard let video = video else {
                    self.imageLoadingIndicator.stopAnimating()
                    self.titleLabel.text = "Untitled Video"
                    self.thumbnail.image = UIImage(named: "Generic Video")
                    self.downloadState = .disabled
                    return
                }
                self.titleLabel.text = video.title
                self.video?.title = video.title
                
                let durationInSeconds = video.duration
                self.video?.durationInSeconds = durationInSeconds
                
                if durationInSeconds.isFinite {
                    self.durationLabel.text = self.getStringFrom(durationInSeconds: durationInSeconds)
                } else {
                    self.durationLabel.text = "Live Broadcast"
                    self.thumbnail.image = UIImage(named: "Broadcast")
                    self.imageLoadingIndicator.stopAnimating()
                    self.downloadState = .disabled
                }
                
                // Load thumbnail image
                let imagePath = self.video!.getThumbnailPath()
                let thumbnailURL = URL(string: "https://i.ytimg.com/vi/\(video.identifier)/maxresdefault.jpg")
                self.imageLoadingIndicator.stopAnimating()
                self.thumbnail.sd_setImage(with: thumbnailURL, placeholderImage: UIImage(named: "Generic Video"), completed: { (image, error, cacheType, url) in
                    DispatchQueue.main.async {
                        if let image = image {
                            let imageData = UIImageJPEGRepresentation(image, 1.0)
                            let _ = FileManager.default.createFile(atPath: imagePath, contents: imageData, attributes: nil)
                        }
                    }
                })
                self.updateVideoDict()
            }
        }
    }
    
    func getStringFrom(durationInSeconds duration: TimeInterval) -> String {
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        let totalMinutes = Int(duration / 60)
        let minutes = Int(Double(totalMinutes).truncatingRemainder(dividingBy: 60))
        let hours = Int(Double(totalMinutes) / 60)
        
        if hours <= 0 {
            return String(format: "%02d:%02d", minutes, seconds)
        } else {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    func updateVideoDict() {
        DispatchQueue.main.async {
            self.videoInfo[VideoInfoKeys.Title] = self.titleLabel.text
            self.videoInfo[VideoInfoKeys.Duration] = self.durationLabel.text
            self.videoInfo[VideoInfoKeys.URL] = self.video?.url.absoluteString
            if self.video!.isYouTube {
                self.videoInfo[VideoInfoKeys.Filename] = self.video?.getYouTubeID()
                self.videoInfo[VideoInfoKeys.Thumbnail] = self.video?.getThumbnailPath()
            } else {
                self.videoInfo[VideoInfoKeys.Filename] = self.video?.filename
                self.videoInfo[VideoInfoKeys.Thumbnail] = self.video?.getThumbnailPath()
            }
            
            let manager = VideoInfoManager.shared
            manager.cache[self.video!.url] = self.videoInfo
            manager.saveVideos()
        }
    }
    
}

