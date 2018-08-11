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

class VideoTableViewCell: UITableViewCell {
    
    
    // MARK: Properties
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var imageLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var videoDownloadProgressView: UIProgressView!
    
    let reachability = Reachability()!
    let videoManager = VideoInfoManager.shared
    var videoInfo: VideoInfo? // For segue to info view controller
    var video: Video? {
        didSet { updateUI() }
    }
    var downloadState: DownloadState = .notDownloaded {
        didSet {
            switch downloadState {
            case .notDownloaded:
                downloadButton.setTitle("↓", for: .normal)
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
    var disabled: Bool = false {
        didSet {
            if !video!.isDownloaded {
                contentView.alpha = disabled ? 0.5 : 1
                setDownloadUI()
                
                isUserInteractionEnabled = !disabled
                titleLabel.isUserInteractionEnabled = !disabled
                durationLabel.isUserInteractionEnabled = !disabled
                downloadButton.isHidden = disabled
            }
        }
    }
    
    func updateUI() {
        thumbnail.image = nil
        titleLabel.text = nil
        durationLabel.text = "00:00"
        durationLabel.isHidden = false
        downloadState = .notDownloaded
        videoDownloadProgressView.isHidden = true
        
        // Load video data
        guard let video = self.video else { return }
        
        if let videoInfo = videoManager.getInfo(for: video) {
            titleLabel.text = videoInfo.title
            durationLabel.text = videoInfo.duration
            if video.isDownloaded {
                downloadState = .downloaded
            }
            if videoInfo.thumbnailUrl != nil {
                thumbnail.image = video.thumbnailImage
            }
            self.imageLoadingIndicator.stopAnimating()
        } else {
            switch video.type {
            case .url:
                loadVideoData(video: video)
            case .youtube:
                loadYouTubeData(video: video)
            }
            return
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(notification:)), name: .reachabilityChanged, object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            print("Could not start reachability notifier")
        }
       
        disabled = reachability.connection == .none && !video.isDownloaded
    }
    
    @objc func reachabilityChanged(notification: Notification) {
        let reachability = notification.object as! Reachability
        
        switch reachability.connection {
        case .none:
            disabled = true
        default:
            updateUI()
        }
    }
    
    func setDownloadUI() {
        // Check for ongoing download task to update progressview
        if let task = DownloadService.shared.getDownloads(withId: video!.url.absoluteString)?.first {
            self.downloadTask = task
            setDownloadProgress()
            setDownloadCompletion()
        }
    }
    
    func setDownloadProgress() {
        downloadState = .inProgress
        durationLabel.isHidden = true
        videoDownloadProgressView.isHidden = false
        videoDownloadProgressView.progress = 0
        self.downloadTask?.progressHandler = { [weak self] in
            self?.videoDownloadProgressView.progress = Float($0)
        }
    }
    
    func setDownloadCompletion() {
        guard let video = self.video else { return }
        downloadTask?.completionHandler = { [weak self] in
            switch $0 {
            case .failure(let error):
                self?.downloadState = .notDownloaded
                print("Video download failed: \(error.localizedDescription)")
            case .success(let data):
                do {
                    try data.write(to: video.filePath, options: [.atomic])
                    DispatchQueue.main.async {
                        self?.videoDownloadProgressView.isHidden = true
                        self?.durationLabel.isHidden = false
                        self?.downloadState = .downloaded
                        if let vc = UIApplication.shared.keyWindow?.rootViewController {
                            Alert.presentDownloadSuccess(on: vc, for: video)
                        }
                    }
                } catch let error {
                    self?.downloadState = .notDownloaded
                    print("Video file save failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @IBAction func setupAssetDownload(_ sender: UIButton) {
        guard let video = video else { return }
        
        let destination = video.filePath
        print(destination)
        
        if !FileManager.default.fileExists(atPath: destination.path) {
            switch downloadState {
            case .notDownloaded:
                var downloadUrl = video.url
                let dispatchGroup = DispatchGroup()
                if video.type == .youtube {
                    dispatchGroup.enter()
                    XCDYouTubeClient.default().getVideoWithIdentifier(video.youtubeID!) { (video, error) in
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
                    self.downloadTask = DownloadService.shared.download(request: request, withId: video.url.absoluteString)
                    self.setDownloadCompletion()
                    DispatchQueue.main.async {
                        self.setDownloadProgress()
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
        titleLabel.text = video.title
        
        // Check if file download exists
        let destination = video.filePath
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
                if let title = titles.first?.value as? String {
                    DispatchQueue.main.async {
                        self.titleLabel.text = title
                    }
                    video.title = title
                }
            }
            
            if durationInSeconds.isFinite {
                DispatchQueue.main.async {
                    self.durationLabel.text = durationInSeconds.formattedString()
                    
                    // Load thumbnail image
                    self.thumbnail.image = video.thumbnailImage
                    self.imageLoadingIndicator.stopAnimating()
                    let imagePath = video.thumbnailPath.absoluteString
                    
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
            self.videoInfo = self.videoManager.updateInfo(for: self.video!)
        }
    }
    
    func loadYouTubeData(video: Video) {
        if video.isDownloaded {
            downloadState = .downloaded
            self.titleLabel.text = video.title
            loadVideoData(video: video)
            return
        }
        titleLabel.text = "Untitled Video"
        imageLoadingIndicator.startAnimating()
        XCDYouTubeClient.default().getVideoWithIdentifier(video.youtubeID) { (ytVideo, error) in
            DispatchQueue.main.async {
                guard let ytVideo = ytVideo else {
                    self.imageLoadingIndicator.stopAnimating()
                    self.titleLabel.text = "Untitled Video"
                    self.thumbnail.image = UIImage(named: "Generic Video")
                    self.downloadState = .disabled
                    return
                }
                self.titleLabel.text = ytVideo.title
                self.video?.title = ytVideo.title
                
                let durationInSeconds = ytVideo.duration
                self.video?.durationInSeconds = durationInSeconds
                
                if durationInSeconds.isFinite {
                    self.durationLabel.text = durationInSeconds.formattedString()
                } else {
                    self.durationLabel.text = "Live Broadcast"
                    self.thumbnail.image = UIImage(named: "Broadcast")
                    self.imageLoadingIndicator.stopAnimating()
                    self.downloadState = .disabled
                }
                
                // Load thumbnail image
                self.thumbnail.image = video.thumbnailImage
                self.imageLoadingIndicator.stopAnimating()
                let thumbnailURL = URL(string: "https://img.youtube.com/vi/\(ytVideo.identifier)/maxresdefault.jpg")
                self.imageLoadingIndicator.stopAnimating()
                self.thumbnail.sd_setImage(with: thumbnailURL, placeholderImage: UIImage(named: "Generic Video"), completed: { (image, error, cacheType, url) in
                    DispatchQueue.main.async {
                        if let image = image {
                            let imageData = UIImageJPEGRepresentation(image, 1.0)
                            let _ = FileManager.default.createFile(atPath: video.thumbnailPath.path, contents: imageData, attributes: nil)
                        }
                    }
                })
                self.videoInfo = self.videoManager.updateInfo(for: self.video!)
            }
        }
    }
    
}

