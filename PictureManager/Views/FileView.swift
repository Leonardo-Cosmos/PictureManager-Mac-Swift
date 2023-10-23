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
    
    @Binding var searchText: String
    
    @Binding var searchScope: SearchFileScope
    
    @AppStorage("FileView.searchMethod")
    private var searchMethod: SearchFileMethod = .substring

    @AppStorage("FileListView.sortBy")
    private var sortBy: SortBy = .name

    @AppStorage("FileListView.viewStyle")
    private var viewStyle: ViewStyle = .list

    @State private var files = [FileInfo]()

    @State private var fileIdDict = [UUID: FileInfo]()

    @State private var selectedIdSet = Set<UUID>()
    
    @Environment(\.isSearching)
    private var isSearching
    
    @State private var searchedFiles = [FileInfo]()
    
    @State private var searchedFileIdDict = [UUID: FileInfo]()
    
    @State private var searchedSelectedIdSet = Set<UUID>()
    
    var body: some View {
        if isSearching {
            FileTreeView(fileInfos: $searchedFiles, selectionSet: $searchedSelectedIdSet)
                .navigationTitle("Searching \(rootDirUrl?.lastPathComponent ?? "")")
                .onChange(of: searchedSelectedIdSet) { idSet in
                    updateSelectedFileUrls(idSet)
                }
                .onChange(of: searchText) { searchText in
                    searchFiles()
                }
                .onChange(of: searchScope) { searchScope in
                    searchFiles()
                }
        } else {
            FileTreeView(fileInfos: $files, selectionSet: $selectedIdSet)
                .navigationTitle(rootDirUrl?.lastPathComponent ?? "")
                .onChange(of: rootDirUrl, perform: loadFiles)
                .onChange(of: selectedIdSet) { idSet in
                    updateSelectedFileUrls(idSet)
                }
                .onCutCommand() { () in
                    let providers = selectedUrls.map(ViewHelper.urlToNSItemProvider)
                    Self.logger.debug("Cut file count: \(providers.count)")
                    return providers
                }
                .onCopyCommand() {
                    let providers = selectedUrls.map(ViewHelper.urlToNSItemProvider)
                    Self.logger.debug("Copied file count: \(providers.count)")
                    return providers
                }
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
        files.removeAll()
        fileIdDict.removeAll()
        selectedIdSet.removeAll()

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
            files.sort { lFile, rFile in
                return lFile.url.purePath < rFile.url.purePath
            }
        }
    }
    
    private func addFiles(fileUrls: [URL], isSearched: Bool = false) {
                
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
            
            if isSearched {
                searchedFileIdDict[file.id] = file
            } else {
                fileIdDict[file.id] = file
            }
            addedFileInfos.append(file)
        }
        
        if isSearched {
            searchedFiles.append(contentsOf: addedFileInfos)
        } else {
            files.append(contentsOf: addedFileInfos)
        }
        Self.logger.debug("File count: \(files.count)")
    }
    
    private func updateSelectedFileUrls(_ idSet: Set<UUID>) {
        let selectedFileSet = idSet
            .map { fileIdDict[$0] }
            .filter { $0 != nil }
        selectedUrls = selectedFileSet.map({ $0!.url })
    }
    
    private func searchFiles() {
        searchedSelectedIdSet.removeAll()
        searchedFiles.removeAll()
        searchedFileIdDict.removeAll()
        
        if let rootDirUrl = rootDirUrl {
            FileUrlProvider.default.listDirectory(dirUrl: rootDirUrl, options: FileUrlProvider.ListDirectoryOptions(fileType: .all, recursive: true,
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
                    Self.logger.debug("File name: \(url.lastPathComponent), matched: \(url.lastPathComponent.contains(searchText))")
                    return url.lastPathComponent.contains(searchText)
                }
            ))
        }
    }
    
}

struct FileListView_Previews: PreviewProvider {
    static var previews: some View {
        FileListView(rootDirUrl: URL(dirPathString: "."), selectedUrls: .constant([URL]()), searchText: .constant(""), searchScope: .constant(.currentDir))
    }
}
