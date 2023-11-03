//
//  FileUrlProvider.swift
//  PictureManager
//
//  Created on 2023/10/20.
//

import Foundation
import os

struct FileUrlProvider {
    
    enum FileType: String {
        case all
        case directory
        case notDirectory
    }
    
    typealias CancellationHandler = () -> Bool
    
    typealias UrlsUpdateHandler = ([URL]) -> Void
    
    typealias UrlsCompletionHandler = ([URL], Error?) -> Void
    
    typealias UrlMatchHandler = (URL) -> Bool
    
    /**
     An object containing option detail for listing directory.
     */
    struct ListDirectoryOption {
        let fileType: FileType
        let recursive: Bool
        let update: UrlsUpdateHandler?
        let complete: UrlsCompletionHandler?
        let isCancelled: CancellationHandler?
        let match: UrlMatchHandler?
        
        /**
         
         - Parameter fileType: The type of file in result.
         - Parameter recursive: A Boolean value that indicates whether list contents of directory recursively.
         - Parameter isCancelled: The handler to check if the operation should be cancelled.
         - Parameter update: The handler to call successively for each directory if there is anyting content matches filter condition.
         - Parameter complete: A completion handler block to execute with the results. The results will be all matched URLs and an optional error.
         - Parameter match: The handler to determine whether an URL should be included in result.
         */
        init(fileType: FileType = .all, recursive: Bool = false, update: UrlsUpdateHandler? = nil, complete: UrlsCompletionHandler? = nil, isCancelled: CancellationHandler? = nil, match: UrlMatchHandler? = nil) {
            self.fileType = fileType
            self.recursive = recursive
            self.isCancelled = isCancelled
            self.update = update
            self.complete = complete
            self.match = match
        }
    }
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
    
    static let defaultInstance = FileUrlProvider()
    
    static var `default`: FileUrlProvider {
        defaultInstance
    }
    
    private let fileManager = FileSystemManager.default
    
    init() {
    }
    
    private func filterUrlByType(urls: [URL], fileType: FileType) -> [URL] {
        var filteredUrls: [URL]
        switch fileType {
        case .all:
            filteredUrls = urls
        case .directory:
            filteredUrls = urls.filter({ url in url.hasDirectoryPath })
        case .notDirectory:
            filteredUrls = urls.filter({ url in !url.hasDirectoryPath })
        }
        return filteredUrls
    }
    
    func listDirectory(dirUrl: URL, fileType: FileType = .all) throws -> [URL] {
        return filterUrlByType(urls: try fileManager.filesOfDirectory(dirUrl: dirUrl), fileType: fileType)
    }
    
    func listDirectory(dirUrl: URL, options: ListDirectoryOption) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            // URL array containing all matched URLs.
            var allUrls: [URL] = []
            
            if options.recursive {
                func listRecursiveDirectory(dirUrl: URL) throws {
                    if options.isCancelled?() ?? false {
                        return
                    }
                  
                    let urls = try listDirectory(dirUrl: dirUrl)
                    var filteredUrls = filterUrlByType(urls: urls, fileType: options.fileType)
                    if let matchUrl = options.match {
                        filteredUrls = filteredUrls.filter(matchUrl)
                    }
                    if !filteredUrls.isEmpty {
                        allUrls.append(contentsOf: filteredUrls)
                        options.update?(filteredUrls)
                    }
                    
                    // List subdirectories
                    for url in urls {
                        if url.hasDirectoryPath {
                            try listRecursiveDirectory(dirUrl: url)
                        }
                    }
                }
                
                do {
                    try listRecursiveDirectory(dirUrl: dirUrl)
                    options.complete?(allUrls, nil)
                } catch let error {
                    options.complete?(allUrls, error)
                }
                
            } else {
                do {
                    let urls = try listDirectory(dirUrl: dirUrl)
                    var filteredUrls = filterUrlByType(urls: urls, fileType: options.fileType)
                    if let matchUrl = options.match {
                        filteredUrls = filteredUrls.filter(matchUrl)
                    }
                    if !filteredUrls.isEmpty {
                        allUrls.append(contentsOf: filteredUrls)
                        options.update?(filteredUrls)
                    }
                    
                    options.complete?(allUrls, nil)
                } catch let error {
                    options.complete?(allUrls, error)
                }
            }
        }
    }
    
}

protocol TextMatcher {
    func match(target: String) -> Bool
}

@available(macOS 13.0, *)
struct RegexMatcher: TextMatcher {
    
    let regex: Regex<Any>
    
    init(pattern: String) throws {
        self.regex = try Regex(pattern)
    }
    
    func match(target: String) -> Bool {
        target.contains(regex)
    }
    
}

struct NSRegexMatcher: TextMatcher {
    
    let regex: NSRegularExpression
    
    init(pattern: String) throws {
        self.regex = try NSRegularExpression(pattern: pattern)
    }
    
    func match(target: String) -> Bool {
        if nil != regex.firstMatch(in: target, range: NSRange(target.startIndex ..< target.endIndex, in: target)) {
            return true
        } else {
            return false
        }
    }
    
}

protocol UrlMatcher {
    func match(url: URL) -> Bool
}

struct UrlPatternMatcher {
    
    let pattern: String
    
    /**
     The handler changes URL object to String for matching.
     */
    let urlConverter: (URL) -> String
    
    /**
     The handler of matching, by the pattern String and the converted String of urlConverter.
     */
    let textMatcher: (String) -> Bool
    
    init(pattern: String, matchingTarget: SearchFileMatchingTarget, matchingMethod: SearchFileMatchingMethod) throws {
        self.pattern = pattern
        
        switch matchingTarget {
        case .name:
            urlConverter = { $0.lastPathComponent }
        case .nameWithoutExtension:
            urlConverter = { $0.deletingPathExtension().lastPathComponent }
        case .nameExtension:
            urlConverter = { $0.pathExtension }
        case .path:
            urlConverter = { $0.purePath }
        case .parentDirPath:
            urlConverter = { $0.deletingLastPathComponent().purePath }
        }
        
        switch matchingMethod {
        case .substring:
            textMatcher = { (target) in target.contains(pattern) }
        case .regex:
            if #available(macOS 13.0, *) {
                let regexMatcher = try RegexMatcher(pattern: pattern)
                textMatcher = regexMatcher.match
            } else {
                let regexMatcher = try NSRegexMatcher(pattern: pattern)
                textMatcher = regexMatcher.match
            }
        }
    }
    
}
