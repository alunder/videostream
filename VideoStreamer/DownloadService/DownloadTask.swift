//
//  DownloadTask.swift
//  DownloadTest
//
//  Created by Ritam Sarmah on 8/28/17.
//  Copyright © 2017 Ritam Sarmah. All rights reserved.
//

import Foundation

protocol DownloadTask {
    
    var completionHandler: ResultType<Data>.Completion? { get set }
    var progressHandler: ((Double) -> Void)? { get set }
    
    func resume()
    func suspend()
    func cancel()
}
