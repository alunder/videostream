//
//  ResultType.swift
//  DownloadTest
//
//  Created by Ritam Sarmah on 8/28/17.
//  Copyright © 2017 Ritam Sarmah. All rights reserved.
//

import Foundation

public enum ResultType<T> {
    
    public typealias Completion = (ResultType<T>) -> Void
    
    case success(T)
    case failure(Swift.Error)
    
}
