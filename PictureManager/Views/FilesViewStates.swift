//
//  FilesViewStates.swift
//  PictureManager
//
//  Created on 2023/10/24.
//

import Foundation

class FileCollectionState: ObservableObject {
    
    /**
     The root in those file views displaying directory hierarchy.
     */
    var rootDir: DirectoryInfo?
    
    /**
     The directory displayed in files view. It is root directory or sub directory of root.
     */
    var currentDir: DirectoryInfo?
    
    /**
     The dictionary of all loaded directories under this root directory.
     */
    var loadedDirDict = [String: DirectoryInfo]()
    
    /**
    The files on root level.
     */
//    @Published var rootFiles = [FileInfo]()

    /**
     All files those are displayed and can be selected in a files view.
     */
    @Published var files = [FileInfo]()

    /**
     The dictionary of all IDs and corresponding file. It contains all loaed files under this root directory.
     */
    @Published var fileIdDict = [UUID: FileInfo]()

    /**
     The set of IDs of selected files.
     */
    @Published var selectedIdSet = Set<UUID>()
    
    /**
     The sort  order of displayed files.
     */
    @Published var sortOrder = [SortDescriptor<FileInfo>]()
    
    init() {
        
    }
    
    func clear() {
        selectedIdSet.removeAll()
        fileIdDict.removeAll()
        files.removeAll()
        loadedDirDict.removeAll()
        currentDir = nil
        rootDir = nil
    }
    
    func addFileId(_ file: FileInfo) {
//        files.add(file)
        fileIdDict[file.id] = file
    }
    
    func removeFileId(id fileId: UUID) {
        selectedIdSet.remove(fileId)
        
        if let index = fileIdDict.index(forKey: fileId) {
            fileIdDict.remove(at: index)
        }
        
//        if let index = files.firstIndex(where: { file in file.id == fileId }) {
//            files.remove(at: index)
//        }
    }
    
}

class SearchOption: ObservableObject {
    
//    static func == (lhs: SearchOption, rhs: SearchOption) -> Bool {
        
        // lhs.scope == rhs.scope && lhs.matchingTarget == rhs.matchingTarget && lhs.matchingMethod == rhs.matchingMethod && lhs.
        
//        if lhs.scope != rhs.scope {
//            return false
//        }
//
//        if lhs.matcher == nil && rhs.matcher == nil {
//            return true
//        } else if lhs.matcher == nil || rhs.matcher == nil {
//            return false
//        }
//
//        if let lMatcher = lhs.matcher as? FileInfoUrlMatcher, let rMatcher = rhs.matcher as? FileInfoUrlMatcher {
//            return lMatcher == rMatcher
//        }
//
//        return false
//    }
    
    @Published var scope: SearchFileScope = .currentDirRecursively
    
//    @Published var pattern: String = ""
//
//    @Published var matchingTarget: SearchFileMatchingTarget = .name
//
//    @Published var matchingMethod: SearchFileMatchingMethod = .substring
    
    @Published var refreshState = false
    
    @Published var matcher: (any FileInfoMatcher)? = nil
    
    func refresh() {
        refreshState.toggle()
    }
    
}

struct SearchedOption: Identifiable {
    
    let id = UUID()
    
    let text: String
    
    init(text: String) {
        self.text = text
    }
    
}
