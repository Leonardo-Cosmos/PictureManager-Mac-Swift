//
//  FileViewEnumerations.swift
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

enum SearchFileMethod: String, CaseIterable, Identifiable {
    case substring
    case regex
    
    var id: SearchFileMethod {
        return self
    }
}
