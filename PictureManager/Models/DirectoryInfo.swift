//
//  DirectoryInfo.swift
//  PictureManager
//
//  Created by Leonardo on 2021/4/11.
//

import Foundation

class DirectoryInfo: Identifiable {
    let id = UUID()
    let content: String
    let children: [DirectoryInfo]?
    init(content: String, children: [DirectoryInfo]? = nil) {
        self.content = content
        self.children = children
    }
}
