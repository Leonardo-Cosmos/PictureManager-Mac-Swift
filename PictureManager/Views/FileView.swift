//
//  FileView.swift
//  PictureManager
//
//  Created on 2021/10/17.
//

import SwiftUI
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

    @AppStorage("FileListView.viewStyle")
    private var viewStyle: ViewStyle = .list

    @StateObject private var status = FileCollectionState()
    
    @Environment(\.isSearching)
    private var isSearching
    
    @StateObject private var searchedStatus = FileCollectionState()
    
    var body: some View {
        if isSearching {
            FileTreeView(fileInfos: $searchedStatus.files, selectionSet: $searchedStatus.selectedIdSet)
                .navigationTitle("Searching \(rootDirUrl?.lastPathComponent ?? "")")
                .onChange(of: searchedStatus.selectedIdSet) { _ in
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
            FileTreeView(fileInfos: $status.files, selectionSet: $status.selectedIdSet)
                .navigationTitle(rootDirUrl?.lastPathComponent ?? "")
                .onChange(of: rootDirUrl, perform: loadFiles)
                .onChange(of: status.selectedIdSet) { _ in
                    updateSelectedFileUrls()
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
                        ViewHelper.urlFromNSItemProvider(provider) { (fileUrl, error) in
                            if let error = error {
                                Self.logger.error("Cannot load pasted path, \(error.localizedDescription)")
                            } else  if let fileUrl = fileUrl {
                                do {
                                    try FileSystemManager.default.copyFile(fileUrl.lastPathComponent, from: fileUrl.deletingLastPathComponent().purePath, to: rootDirUrl!.purePath)
                                    addFiles(fileUrls: [fileUrl])
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
        status.files.removeAll()
        status.fileIdDict.removeAll()
        status.selectedIdSet.removeAll()

        guard let dirUrl = dirUrl else {
            return
        }

        Self.logger.debug("List files of directory \(dirUrl.purePath)")

        var fileUrls: [URL]
        do {
            fileUrls = try FileSystemManager.default.filesOfDirectory(dirUrl: dirUrl)
        } catch let error as NSError {
            Self.logger.error("Cannot list files. \(error)")
            return
        }

        addFiles(fileUrls: fileUrls)

        if sortBy == .name {
            status.files.sort { lFile, rFile in
                return lFile.url.purePath < rFile.url.purePath
            }
        }
    }
    
    private func addFiles(fileUrls: [URL], isSearched: Bool = false) {
        
        let status = isSearched ? searchedStatus : status
                
        var addedFileInfos: [FileInfo] = []
        var file: FileInfo
        for fileUrl in fileUrls {
            if fileUrl.hasDirectoryPath {
                file = DirectoryInfo(url: fileUrl)
            } else if ViewHelper.isImage(url: fileUrl) {
                file = ImageFileInfo(url: fileUrl)
            } else {
                file = FileInfo(url: fileUrl)
            }
            
            status.fileIdDict[file.id] = file
            addedFileInfos.append(file)
        }
        
        status.files.append(contentsOf: addedFileInfos)
        Self.logger.debug("File count: \(status.files.count)")
    }
    
    private func updateSelectedFileUrls(isSearched: Bool = false) {
        let status = isSearched ? searchedStatus : status
        
        let updatedSelectedUrls = status.selectedIdSet
            .map { id in status.fileIdDict[id] }
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
        
        searchedStatus.selectedIdSet.removeAll()
        searchedStatus.files.removeAll()
        searchedStatus.fileIdDict.removeAll()
        
        if let rootDirUrl = rootDirUrl {
            FileUrlProvider.default.listDirectory(dirUrl: rootDirUrl, options: FileUrlProvider.ListDirectoryOption(fileType: .all, recursive: true,
                update: { urls in
                    DispatchQueue.main.async {
                        addFiles(fileUrls: urls, isSearched: true)
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
