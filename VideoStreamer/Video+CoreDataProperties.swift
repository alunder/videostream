//
//  Video+CoreDataProperties.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 9/8/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import Foundation
import CoreData


extension Video {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Video> {
        return NSFetchRequest<Video>(entityName: "Video");
    }

    @NSManaged public var url: String?
    @NSManaged public var filename: String?
    @NSManaged public var lastPlayedTime: NSData?

}
