//
//  GenericDownloadTask.swift
//
//  Created by Ritam Sarmah on 8/28/17.
//  Copyright © 2017 Ritam Sarmah. All rights reserved.
//

import Foundation

class GenericDownloadTask {
    
    var completionHandler: ResultType<Data>.Completion?
    var progressHandler: ((Double) -> Void)?
    
    private(set) var task: URLSessionDataTask
    var expectedContentLength: Int64 = 0
    var buffer = Data()
    var id: String?
    
    init(task: URLSessionDataTask, id: String?) {
        self.task = task
        self.id = id
    }
    
    deinit {
        print("Deinit: \(task.originalRequest?.url?.absoluteString ?? "")")
    }
    
}

extension GenericDownloadTask: DownloadTask {
    
    func resume() {
        task.resume()
    }
    
    func suspend() {
        task.suspend()
    }
    
    func cancel() {
        task.cancel()
    }
}
