//
//  RegularFileInfo.swift
//  PictureManager
//
//  Created on 2023/11/2.
//

import Foundation

class RegularFileInfo: FileInfo {
    
    @Published var fileSize: Int?
    
    override init(url: URL) {
        super.init(url: url)
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
    
}
