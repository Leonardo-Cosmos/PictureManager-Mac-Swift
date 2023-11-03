//
//  DirectoryInfo.swift
//  PictureManager
//
//  Created on 2021/4/11.
//

import Foundation

class DirectoryInfo: FileInfo {
    
    var children: [DirectoryInfo]?
    
    var error: Error?
    
    init(url: URL, children: [DirectoryInfo]? = nil) {
        super.init(url: url)
        
        self.children = children
    }
    
    convenience init(path: String, children: [DirectoryInfo]? = nil) {
        self.init(url: URL(dirPathString: path), children: children)
    }
    
}
