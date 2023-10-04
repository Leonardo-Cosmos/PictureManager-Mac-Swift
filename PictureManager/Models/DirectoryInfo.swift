//
//  DirectoryInfo.swift
//  PictureManager
//
//  Created on 2021/4/11.
//

import Foundation

class DirectoryInfo: Identifiable, Hashable, Equatable, ObservableObject {
    
    static func == (lhs: DirectoryInfo, rhs: DirectoryInfo) -> Bool {
        lhs.url == rhs.url
    }
    
    let id = UUID()
    
    let url: URL
    
    var children: [DirectoryInfo]?
    
    var error: Error?
    
    init(url: URL, children: [DirectoryInfo]? = nil) {
        self.url = url
        self.children = children
    }
    
    var name: String {
        url.lastPathComponent
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
