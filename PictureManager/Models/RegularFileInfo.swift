//
//  RegularFileInfo.swift
//  PictureManager
//
//  Created on 2023/11/2.
//

import Foundation

class RegularFileInfo: FileInfo {
    
    override init(url: URL, parent: DirectoryInfo? = nil) {
        super.init(url: url, parent: parent)
    }
    
    override var resourceKeySet: Set<URLResourceKey> {
        var resourceKeySet = super.resourceKeySet
        resourceKeySet.insert(.fileSizeKey)
        resourceKeySet.insert(.fileAllocatedSizeKey)
        resourceKeySet.insert(.totalFileSizeKey)
        resourceKeySet.insert(.totalFileAllocatedSizeKey)
        return resourceKeySet
    }
    
    override func populateResourceValues(_ resourceValues: URLResourceValues) {
        super.populateResourceValues(resourceValues)
        fileSize = resourceValues.fileSize
    }
    
    override func populateResourceValues(_ resourceValues: URL.SendableResourceValues) {
        super.populateResourceValues(resourceValues)
        fileSize = resourceValues.fileSize
    }
    
}
