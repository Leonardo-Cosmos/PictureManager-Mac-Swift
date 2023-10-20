//
//  FileInfo.swift
//  PictureManager
//
//  Created on 2021/4/11.
//

import Foundation
import SwiftUI

class FileInfo: Identifiable, Hashable, Equatable, ObservableObject {
    
    static func == (lhs: FileInfo, rhs: FileInfo) -> Bool {
        lhs.url == rhs.url
    }
    
    let id = UUID()
    
    let url: URL
    
    let thumbnail = ThumbnailCache()
    
    init(url: URL) {
        self.url = url
    }
    
    var name: String {
        url.lastPathComponent
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
}
