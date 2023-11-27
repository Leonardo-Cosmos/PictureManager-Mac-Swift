//
//  DirectoryInfo.swift
//  PictureManager
//
//  Created on 2021/4/11.
//

import Foundation

class DirectoryInfo: FileInfo {
    
    var children: [DirectoryInfo]?
    
    @Published var files: [FileInfo] = []
    
    @Published var error: Error?
    
    init(url: URL, parent: DirectoryInfo? = nil, children: [DirectoryInfo]? = nil) {
        super.init(url: url, parent: parent)
        
        self.children = children
    }
    
    convenience init(path: String, parent: DirectoryInfo? = nil, children: [DirectoryInfo]? = nil) {
        self.init(url: URL(dirPathString: path), parent: parent, children: children)
    }
    
}
