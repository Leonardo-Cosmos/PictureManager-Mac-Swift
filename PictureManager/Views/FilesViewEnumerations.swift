//
//  FilesViewEnumerations.swift
//  PictureManager
//
//  Created on 2023/10/17.
//

import Foundation

enum SortBy: String, CaseIterable, Identifiable {
    case name = "name"
    case creationDate = "creationDate"
    case contentModificationDate = "contentModificationDate"
    case contentAccessDate = "contentAccessDate"
    case addedToDirectoryDate = "addedToDirectoryDate"
    case attributeModificationDate = "attributeModificationDate"
    case size = "size"

    var id: SortBy {
        return self
    }
}

enum SortDirection: String, CaseIterable, Identifiable {
    case forward = "forward"
    case reverse = "reverse"
    
    var id: SortDirection {
        return self
    }
}

enum ViewStyle: String, CaseIterable, Identifiable {
    case icon = "icon"
    case list = "list"

    var id: ViewStyle {
        return self
    }
}

enum SearchFileScope: String, CaseIterable, Identifiable {
    case currentDir
    case currentDirRecursively
    case rootDirRecursively
    
    var id: SearchFileScope {
        return self
    }
    
    var isCurrentDir: Bool {
        return self == .currentDir || self == .currentDirRecursively
    }
    
    var isRecursive: Bool {
        return self == .currentDirRecursively || self == .rootDirRecursively
    }
    
    var description: String {
        var text: String
        switch self {
        case .currentDir:
            text = "Current Folder Only"
        case .currentDirRecursively:
            text = "Current Folder Recursively"
        case .rootDirRecursively:
            text = "Root Folder Recursively"
        }
        return text
    }
}

enum SearchFileMatchingMethod: String, CaseIterable, Identifiable {
    case substring
    case regex
    
    var id: SearchFileMatchingMethod {
        return self
    }
}

enum SearchFileMatchingTarget: String, CaseIterable, Identifiable {
    case name
    case nameWithoutExtension
    case nameExtension
    case path
    case parentDirPath
    
    var id: SearchFileMatchingTarget {
        return self
    }
}
