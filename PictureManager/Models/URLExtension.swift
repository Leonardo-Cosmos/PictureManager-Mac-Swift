//
//  URLExtension.swift
//  PictureManager
//
//  Created on 2023/10/20.
//

import Foundation

extension URL {
    
    init(filePathString: String) {
        if #available(macOS 13.0, *) {
            self.init(filePath: filePathString)
        } else {
            self.init(fileURLWithPath: filePathString)
        }
    }
    
    init(fileNotDirPathString: String) {
        if #available(macOS 13.0, *) {
            self.init(filePath: fileNotDirPathString, directoryHint: .notDirectory)
        } else {
            self.init(fileURLWithPath: fileNotDirPathString, isDirectory: false)
        }
    }
    
    init(dirPathString: String) {
        if #available(macOS 13.0, *) {
            self.init(filePath: dirPathString, directoryHint: .isDirectory)
        } else {
            self.init(fileURLWithPath: dirPathString, isDirectory: true)
        }
    }
    
    var purePath: String {
        if #available(macOS 13.0, *) {
            return self.path(percentEncoded: false)
//            var path = self.path(percentEncoded: false)
//            if path.last == "/" {
//                path.removeLast()
//            }
//            return path
        } else {
            return self.path
        }
    }
    
    func appending(pathString: String) -> URL {
        if #available(macOS 13.0, *) {
            return appending(path: pathString)
        } else {
            return appendingPathComponent(pathString)
        }
    }
    
    func sendableResourceValues(forKeys resourceKeySet: Set<URLResourceKey>) throws -> SendableResourceValues {
        let resourceValues = try resourceValues(forKeys: resourceKeySet)
        return SendableResourceValues(resourceValues)
    }
    
    struct SendableResourceValues: Sendable {
        
        let creationDate: Date?
        let contentModificationDate: Date?
        let contentAccessDate: Date?
        let addedToDirectoryDate: Date?
        let attributeModificationDate: Date?
        let fileSize: Int?
        
        init(_ resourceValues: URLResourceValues) {
            creationDate = resourceValues.creationDate
            contentModificationDate = resourceValues.contentModificationDate
            contentAccessDate = resourceValues.contentAccessDate
            addedToDirectoryDate = resourceValues.addedToDirectoryDate
            attributeModificationDate = resourceValues.attributeModificationDate
            fileSize = resourceValues.fileSize
        }
        
    }
    
}
