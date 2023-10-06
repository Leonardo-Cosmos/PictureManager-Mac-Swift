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
    
    private let fileManager = FileManager.default
    
    init() {
    }
    
    /**
     Searches items of specified directory.
     
     - Parameter path: The path to the directory whose contents you want to enumerate.
     
     - Returns: An array of NSString objects, each of which identifies a file, directory, or symbolic link contained in path. Returns an empty array if the directory exists but has no contents.
     
     */
    func contentsOfDirectory(atPath path: String) throws -> [String] {
        var contents = try fileManager.contentsOfDirectory(atPath: path)
        contents = contents.map { content in "\(path)/\(content)" }
        
        return contents
    }
    
    private func filterContentOfDirectory(atPath path: String, _ isIncluded: (String) -> Bool) throws -> [String] {
        let contents = try contentsOfDirectory(atPath: path)
        return contents.filter(isIncluded)
    }
    
    func filesOfDirectory(atPath path: String) throws -> [String] {
        return try filterContentOfDirectory(atPath: path) { content in
            var isDirectory: ObjCBool = false
            let exists = fileManager.fileExists(atPath: content, isDirectory: &isDirectory)
            return exists && !isDirectory.boolValue
        }
    }
    
    func directoriesOfDirectory(atPath path: String) throws -> [String] {
        return try filterContentOfDirectory(atPath: path) { content in
            var isDirectory: ObjCBool = false
            let exists = fileManager.fileExists(atPath: content, isDirectory: &isDirectory)
            return exists && isDirectory.boolValue
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
    
    func moveFile(fromPath srcPath: String, toPath dstPath: String) {
        
        Self.logger.debug("Move \(srcPath) to \(dstPath)")
        do {
            try fileManager.moveItem(atPath: srcPath, toPath: dstPath)
        } catch let error as NSError {
            Self.logger.error("Cannot move file: \(error)")
        }
    }
    
    func moveFile(_ fileName: String, from srcDirPath: String, to dstDirPath: String) {
        
        let srcPath = "\(srcDirPath)/\(fileName)"
        let dstPath = "\(dstDirPath)/\(fileName)"
        moveFile(fromPath: srcPath, toPath: dstPath)
    }
    
    func renameFile(atPath dirPath: String, from srcFileName: String, to dstFileName: String) {
        
        let srcPath = "\(dirPath)/\(srcFileName)"
        let dstPath = "\(dirPath)/\(dstFileName)"
        Self.logger.debug("Rename \(srcFileName) to \(dstFileName)")
        moveFile(fromPath: srcPath, toPath: dstPath)
    }
    
    func copyFile(fromPath srcPath: String, toPath dstPath: String) {
        
        Self.logger.debug("Copy \(srcPath) to \(dstPath)")
        do {
            try fileManager.copyItem(atPath: srcPath, toPath: dstPath)
        } catch let error as NSError {
            Self.logger.error("Cannot copy file: \(error)")
        }
    }
    
    func copyFile(_ fileName: String, from srcDirPath: String, to dstDirPath: String) {
        
        let srcPath = "\(srcDirPath)/\(fileName)"
        let dstPath = "\(dstDirPath)/\(fileName)"
        copyFile(fromPath: srcPath, toPath: dstPath)
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
    
    static let defaultInstance = FileSystemManager()
    
    static var `default`: FileSystemManager {
        defaultInstance
    }
}
