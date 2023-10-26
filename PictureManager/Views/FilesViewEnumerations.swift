//
//  FilesViewEnumerations.swift
//  PictureManager
//
//  Created on 2023/10/17.
//

import Foundation

enum SortBy: String, CaseIterable, Identifiable {
    case name = "name"
    case dateModified = "dateModified"
    case dateCreated = "dateCreated"
    case size = "size"

    var id: SortBy {
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
