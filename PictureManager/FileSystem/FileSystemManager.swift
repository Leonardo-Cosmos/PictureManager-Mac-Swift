//
//  FileSystemManager.swift
//  PictureManager
//
//  Created on 2021/9/4.
//

import Foundation
import os

struct FileSystemManager {
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
    
    static let defaultInstance = FileSystemManager()
    
    static var `default`: FileSystemManager {
        defaultInstance
    }
    
    private let fileManager = FileManager.default
    
    init() {
    }
    
    /**
     Searches items of specified directory and returns the full paths of any contained items.
     
     - Parameter path: The path to the directory whose contents you want to enumerate.
     
     - Returns: An array of URL objects, each of which identifies a file, directory, or symbolic link contained in path. Returns an empty array if the directory exists but has no contents.
     
     */
    func filesOfDirectory(dirUrl: URL) throws -> [URL] {
        guard dirUrl.hasDirectoryPath else {
            throw NSError(domain: NSURLErrorDomain, code: 0, userInfo: [
                NSLocalizedDescriptionKey: "URL doesn't identify a directory path",
                NSFilePathErrorKey: dirUrl.purePath
            ])
        }
        
        let contents = try fileManager.contentsOfDirectory(atPath: dirUrl.purePath)
        let urls = contents.map { content -> URL? in
            var fileUrl = dirUrl.appending(pathString: content)
            if let isDirectory = isDirectoryPath(atPath: fileUrl.purePath) {
                if isDirectory {
                    fileUrl = URL(dirPathString: fileUrl.purePath)
                }
            } else {
                return nil
            }
            return fileUrl
        }.filter({ $0 != nil }).map({ $0! })
        
        return urls
    }
    
    func isDirectoryPath(atPath path: String) -> Bool? {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        if !exists {
            return nil
        } else {
            return isDirectory.boolValue
        }
    }
    
    func traverseFiles(atPath dirPath: String, do action: (String) -> Void) {
        let files: [String]
        do {
            files = try fileManager.contentsOfDirectory(atPath: dirPath)
        } catch let error as NSError {
            Self.logger.error("Cannot get contents: \(error)")
            return
        }
        
        for file in files {
            
            if file == ".DS_Store" {
                continue
            }
            
            action(file)
        }
    }
    
    func moveFile(fromPath srcPath: String, toPath dstPath: String) throws {
        Self.logger.debug("Move \(srcPath) to \(dstPath)")
        try fileManager.moveItem(atPath: srcPath, toPath: dstPath)
    }
    
    func moveFile(_ fileName: String, from srcDirPath: String, to dstDirPath: String) throws {
        let srcPath = "\(srcDirPath)/\(fileName)"
        let dstPath = "\(dstDirPath)/\(fileName)"
        try moveFile(fromPath: srcPath, toPath: dstPath)
    }
    
    func renameFile(atPath dirPath: String, from srcFileName: String, to dstFileName: String) throws {
        let srcPath = "\(dirPath)/\(srcFileName)"
        let dstPath = "\(dirPath)/\(dstFileName)"
        Self.logger.debug("Rename \(srcFileName) to \(dstFileName)")
        try moveFile(fromPath: srcPath, toPath: dstPath)
    }
    
    func copyFile(fromPath srcPath: String, toPath dstPath: String) throws {
        Self.logger.debug("Copy \(srcPath) to \(dstPath)")
        try fileManager.copyItem(atPath: srcPath, toPath: dstPath)
    }
    
    func copyFile(_ fileName: String, from srcDirPath: String, to dstDirPath: String) throws {
        let srcPath = "\(srcDirPath)/\(fileName)"
        let dstPath = "\(dstDirPath)/\(fileName)"
        try copyFile(fromPath: srcPath, toPath: dstPath)
    }
    
    func attributes(_ filePath: String) throws -> [FileAttributeKey: Any] {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: filePath)
            return attributes
        } catch let error as NSError {
            Self.logger.error("Cannot get attributes of \(filePath): \(error)")
            throw error
        }
    }
    
    static func size(attributes: [FileAttributeKey: Any]) -> UInt64 {
        return attributes[FileAttributeKey.size] as! UInt64
    }
    
    func size(filePath: String) throws -> UInt64 {
        return try FileSystemManager.size(attributes: self.attributes(filePath))
    }
    
    static func type(attributes: [FileAttributeKey: Any]) -> String {
        return attributes[FileAttributeKey.type] as! String
    }
    
    func type(filePath: String) throws -> String {
        return try FileSystemManager.type(attributes: self.attributes(filePath))
    }
    
}

