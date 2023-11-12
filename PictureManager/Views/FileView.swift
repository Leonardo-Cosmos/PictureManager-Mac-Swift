//
//  FileView.swift
//  PictureManager
//
//  Created on 2021/10/17.
//

import SwiftUI
import System
import UniformTypeIdentifiers
import os

struct FileListView: View {
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
    
    /**
     Root directory is the one selected in directory tree view and is the root in those file views displaying directory hierarchy.
     */
    var rootDirUrl: URL?
    
    @Binding var selectedUrls: [URL]
    
    @ObservedObject var searchOption: SearchOption
    
    @AppStorage("FileView.searchMethod")
    private var searchMethod: SearchFileMatchingMethod = .substring

    @AppStorage("FileListView.sortBy")
    private var sortBy: SortBy = .name
    
    @AppStorage("FileListView.sortOrder")
    private var sortDirection: SortDirection = .reverse

    @AppStorage("FileListView.viewStyle")
    private var viewStyle: ViewStyle = .list

    @StateObject private var filesState = FileCollectionState()
    
    @Environment(\.isSearching)
    private var isSearching
    
    @StateObject private var searchedFilesState = FileCollectionState()
    
    var body: some View {
        if isSearching {
            FileTreeView(fileInfos: $searchedFilesState.files, selectionSet: $searchedFilesState.selectedIdSet, sortOrder: $searchedFilesState.sortOrder)
                .navigationTitle("Searching \(rootDirUrl?.lastPathComponent ?? "")")
                .onChange(of: searchedFilesState.selectedIdSet) { _ in
                    updateSelectedFileUrls(isSearched: true)
                }
                .onChange(of: searchOption.pattern) { _ in
                    searchFiles()
                }
                .onChange(of: searchOption.scope) { _ in
                    searchFiles()
                }
                .onCutCommand(perform: cutSelectedUrls)
                .onCopyCommand(perform: copySelectedUrls)
        } else {
            FileTreeView(fileInfos: $filesState.files, selectionSet: $filesState.selectedIdSet, sortOrder: $filesState.sortOrder)
                .navigationTitle(rootDirUrl?.lastPathComponent ?? "")
                .onChange(of: rootDirUrl, perform: loadFiles)
                .onChange(of: filesState.selectedIdSet) { _ in
                    updateSelectedFileUrls()
                }
                .onChange(of: filesState.sortOrder) { _ in
                    sortFiles(state: filesState)
                }
                .onCutCommand(perform: cutSelectedUrls)
                .onCopyCommand(perform: copySelectedUrls)
                .onPasteCommand(of: [UTType.fileListPath.identifier], validator: { providers in
                    guard rootDirUrl != nil else {
                        return nil
                    }
                    return providers
                }, perform: { (providers: [NSItemProvider]) in
                    for provider in providers {
                        ViewHelper.pathFromNSItemProvider(provider) { (path, error) in
                            if let error = error {
                                Self.logger.error("Cannot load pasted path, \(error.localizedDescription)")
                            } else  if let path = path {
                                do {
                                    let filePath = FilePath(path)
                                    try FileSystemManager.default.copyFile(filePath.lastComponent!.string, from: filePath.removingLastComponent().string, to: rootDirUrl!.purePath)
                                    
                                    // TODO: add pasted file together.
                                    DispatchQueue.main.async {
                                        addFiles(filePaths: [path])
                                    }
                                    
                                } catch let error {
                                    Self.logger.error("Cannot paste file, \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                })
        }
    }

    private func loadFiles(dirUrl: URL?) {
        filesState.selectedIdSet.removeAll()
        filesState.fileIdDict.removeAll()
        filesState.files.removeAll()

        guard let dirUrl = dirUrl else {
            return
        }

        Self.logger.debug("List files of directory \(dirUrl.purePath)")

        var filePaths: [String]
        do {
            filePaths = try FileSystemManager.default.filesOfDirectory(dirPath: dirUrl.purePath)
        } catch let error as NSError {
            Self.logger.error("Cannot list files. \(error)")
            return
        }
        
        if sortBy == .name {
            filesState.sortOrder.append(SortDescriptor<FileInfo>(\.contentModificationDate))
        }
        
        

        addFiles(filePaths: filePaths)
    }
    
    private func addFiles(filePaths: [String], isSearched: Bool = false) {
        
        let status = isSearched ? searchedFilesState : filesState
                
        var addedFiles: [FileInfo] = []
        var file: FileInfo
        for filePath in filePaths {
            guard let fileAttributes = try? FileSystemManager.default.attributes(filePath) else {
                continue
            }
            
            let fileType = FileSystemManager.type(attributes: fileAttributes)
            
            switch fileType {
            case FileAttributeType.typeDirectory:
                file = DirectoryInfo(path: filePath)
            case FileAttributeType.typeRegular:
                if ViewHelper.isImage(path: filePath) {
                    file = ImageFileInfo(path: filePath)
                } else {
                    file = RegularFileInfo(path: filePath)
                }
            default:
                file = FileInfo(path: filePath)
            }
            
            file.permissions = FileSystemManager.posixPermissions(attributes: fileAttributes)
            
            status.fileIdDict[file.id] = file
            addedFiles.append(file)
        }
        
        status.files.append(contentsOf: addedFiles)
        
        ViewHelper.loadUrlResourceValues(files: addedFiles) {
            sortFiles(state: status)
        }
        Self.logger.debug("Added file count: \(addedFiles.count), total file count: \(status.files.count)")
    }
    
    private func sortFiles(state: FileCollectionState) {
        filesState.files.sort(using: filesState.sortOrder.first!)
    }
    
    private func updateSelectedFileUrls(isSearched: Bool = false) {
        let state = isSearched ? searchedFilesState : filesState
        
        let updatedSelectedUrls = state.selectedIdSet
            .map { id in state.fileIdDict[id] }
            .filter { $0 != nil }
            .map { $0!.url }
        
        let updatedSelectedUrlSet = Set(updatedSelectedUrls)
        let existingSelectedUrlSet = Set(selectedUrls)
        
        let removedUrls = existingSelectedUrlSet.subtracting(updatedSelectedUrlSet)
        let addedUrls = updatedSelectedUrlSet.subtracting(existingSelectedUrlSet)
        
        selectedUrls.removeAll { url in removedUrls.contains(url) }
        selectedUrls.append(contentsOf: addedUrls)
    }
    
    private func cutSelectedUrls() -> [NSItemProvider] {
        let providers = selectedUrls.map(ViewHelper.urlToNSItemProvider)
        Self.logger.debug("Cut file count: \(providers.count)")
        return providers
    }
    
    private func copySelectedUrls() -> [NSItemProvider] {
        let providers = selectedUrls.map(ViewHelper.urlToNSItemProvider)
        Self.logger.debug("Copied file count: \(providers.count)")
        return providers
    }
    
    private func searchFiles() {
        Self.logger.info("Searching pattern: \(searchOption.pattern), in: \(searchOption.scope.rawValue), of: \(searchOption.matchingTarget.rawValue), by: \(searchOption.matchingMethod.rawValue)")
        
        searchedFilesState.selectedIdSet.removeAll()
        searchedFilesState.files.removeAll()
        searchedFilesState.fileIdDict.removeAll()
        
        let recursive = searchOption.scope == .currentDirRecursively || searchOption.scope == .rootDirRecursively
        
        if let rootDirUrl = rootDirUrl {
            FileUrlProvider.default.listDirectory(dirUrl: rootDirUrl, options: FileUrlProvider.ListDirectoryOption(fileType: .all, recursive: recursive,
                update: { urls in
                    let paths = urls.map { $0.purePath }
                    DispatchQueue.main.async {
                        addFiles(filePaths: paths, isSearched: true)
                    }
                },
                complete: { (_, error) in
                    if let error = error {
                        Self.logger.error("Search file error: \(error)")
                    }
                },
                match: { url in
                    return url.lastPathComponent.contains(searchOption.pattern)
                }
            ))
        }
    }
    
}

struct FileListView_Previews: PreviewProvider {
    static var previews: some View {
        FileListView(rootDirUrl: URL(dirPathString: "."), selectedUrls: .constant([URL]()), searchOption: SearchOption())
    }
}
