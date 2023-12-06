//
//  FileSearchMatcher.swift
//  PictureManager
//
//  Created on 2023/12/5.
//

import Foundation

protocol TextMatcher {
    func match(target: String) -> Bool
}

@available(macOS 13.0, *)
struct RegexMatcher: TextMatcher {
    
    let regex: Regex<Substring>
    
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

protocol UrlMatcher: Equatable {
    func match(url: URL) -> Bool
}

struct UrlPatternMatcher: UrlMatcher {
    
    static func == (lhs: UrlPatternMatcher, rhs: UrlPatternMatcher) -> Bool {
        lhs.pattern == rhs.pattern && lhs.matchingTarget == rhs.matchingTarget && lhs.matchingMethod == rhs.matchingMethod
    }
    
    let pattern: String
    
    let matchingTarget: SearchFileMatchingTarget
    
    let matchingMethod: SearchFileMatchingMethod
    
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
        self.matchingTarget = matchingTarget
        self.matchingMethod = matchingMethod
        
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
    
    func match(url: URL) -> Bool {
        textMatcher(urlConverter(url))
    }
    
}

protocol FileInfoMatcher: Equatable {
    func match(file: FileInfo) -> Bool
}

struct FileInfoUrlMatcher: FileInfoMatcher {
    
    static func == (lhs: FileInfoUrlMatcher, rhs: FileInfoUrlMatcher) -> Bool {
        if let lMatcher = lhs.urlMatcher as? UrlPatternMatcher, let rMatcher = rhs.urlMatcher as? UrlPatternMatcher {
            print("Is same url matcher: \(lMatcher == rMatcher), \(lMatcher.pattern) \(rMatcher.pattern)")
            return lMatcher == rMatcher
        }
        
        return false
    }
    
    let urlMatcher: any UrlMatcher
    
    init(urlMatcher: any UrlMatcher) {
        self.urlMatcher = urlMatcher
    }
    
    func match(file: FileInfo) -> Bool {
        urlMatcher.match(url: file.url)
    }
    
}
