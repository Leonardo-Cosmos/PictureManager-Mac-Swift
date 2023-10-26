//
//  FilesViewStates.swift
//  PictureManager
//
//  Created on 2023/10/24.
//

import Foundation

class FileCollectionState: ObservableObject {

    /**
     All files.
     */
    @Published var files = [FileInfo]()

    /**
     The dictionary of all IDs and corresponding file.
     */
    @Published var fileIdDict = [UUID: FileInfo]()

    /**
     The set of IDs of selected files.
     */
    @Published var selectedIdSet = Set<UUID>()
    
}

class SearchOption: ObservableObject, Equatable {
    
    static func == (lhs: SearchOption, rhs: SearchOption) -> Bool {
        lhs.pattern == rhs.pattern && lhs.scope == rhs.scope && lhs.matchingTarget == rhs.matchingTarget && lhs.matchingMethod == rhs.matchingMethod
    }
    
    @Published var pattern: String = ""
    
    @Published var scope: SearchFileScope = .currentDirRecursively
    
    @Published var matchingTarget: SearchFileMatchingTarget = .name
    
    @Published var matchingMethod: SearchFileMatchingMethod = .substring
}

struct SearchedOption: Identifiable {
    
    let id = UUID()
    
    let text: String
    
    init(text: String) {
        self.text = text
    }
    
}
