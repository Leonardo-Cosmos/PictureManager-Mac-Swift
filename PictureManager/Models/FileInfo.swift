//
//  FileInfo.swift
//  PictureManager
//
//  Created on 2021/4/11.
//

import Foundation
import SwiftUI
import System

@objc(FileInfo)
class FileInfo: NSObject, Identifiable, ObservableObject {
    
    static func == (lhs: FileInfo, rhs: FileInfo) -> Bool {
        lhs.url == rhs.url
    }
    
    let id = UUID()
    
    let url: URL
    
    let parent: DirectoryInfo?
    
    var ancients: [DirectoryInfo] {
        var pathDirectories: [DirectoryInfo] = []
        
        var parent = parent
        while (parent != nil) {
            pathDirectories.append(parent!)
            parent = parent?.parent
        }
        return pathDirectories.reversed()
    }
    
    let thumbnail = ThumbnailCache()
    
    @Published var permissions: Int16?
    
    @objc @Published var creationDate: Date?
    
    @objc @Published var contentModificationDate: Date?
    
    @objc @Published var contentAccessDate: Date?
    
    @objc @Published var addedToDirectoryDate: Date?
    
    @Published var attributeModificationDate: Date?
    
    @Published var fileSize: Int?
    
    init(url: URL, parent: DirectoryInfo?) {
        self.url = url
        self.parent = parent
    }
    
    convenience init(path: String, parent: DirectoryInfo?) {
        self.init(url: URL(fileNotDirPathString: path), parent: parent)
    }
    
    @objc var name: String {
        url.lastPathComponent
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else {
            return false
        }
        return url == other.url
    }
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(super.hash)
        hasher.combine(url)
        return hasher.finalize()
    }
    
    var resourceKeySet: Set<URLResourceKey> {
        var resourceKeySet = Set<URLResourceKey>()
        resourceKeySet.insert(.fileResourceTypeKey)
        
        resourceKeySet.insert(.creationDateKey)
        resourceKeySet.insert(.contentModificationDateKey)
        resourceKeySet.insert(.contentAccessDateKey)
        resourceKeySet.insert(.addedToDirectoryDateKey)
        resourceKeySet.insert(.attributeModificationDateKey)
        
        return resourceKeySet
    }
    
    func populateResourceValues(_ resourceValues: URLResourceValues) {
        creationDate = resourceValues.creationDate
        contentModificationDate = resourceValues.contentModificationDate
        contentAccessDate = resourceValues.contentAccessDate
        addedToDirectoryDate = resourceValues.addedToDirectoryDate
        attributeModificationDate = resourceValues.attributeModificationDate
    }
    
    func populateResourceValues(_ resourceValues: URL.SendableResourceValues) {
        creationDate = resourceValues.creationDate
        contentModificationDate = resourceValues.contentModificationDate
        contentAccessDate = resourceValues.contentAccessDate
        addedToDirectoryDate = resourceValues.addedToDirectoryDate
        attributeModificationDate = resourceValues.attributeModificationDate
    }
    
}
