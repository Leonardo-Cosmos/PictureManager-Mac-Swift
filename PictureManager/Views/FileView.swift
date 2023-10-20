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

    @State private var fileInfos = [FileInfo]()

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
                    Self.logger.info("Search: \(searchText)")
                }
                .onChange(of: searchScope) { searchScope in
                    
                }
        } else {
            FileTreeView(fileInfos: $fileInfos, selectionSet: $selectedIdSet)
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
                                    addFile(fileUrl: fileUrl)
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
        fileInfos.removeAll()
        fileIdDict.removeAll()
        selectedIdSet.removeAll()

        guard let dirUrl = dirUrl else {
            return
        }

        Self.logger.debug("List files of directory \(dirUrl.purePath)")

        var fileUrls: [URL]
        do {
            fileUrls = try FileSystemManager.default.itemsOfDirectory(dirUrl: dirUrl)
        } catch let error as NSError {
            Self.logger.error("Cannot list files. \(error)")
            return
        }

        fileUrls.forEach(addFile)

        if sortBy == .name {
            fileInfos.sort { lFile, rFile in
                return lFile.url.purePath < rFile.url.purePath
            }
        }
    }
    
    private func addFile(fileUrl: URL) {
        var file: FileInfo
        
        if fileUrl.hasDirectoryPath {
            file = DirectoryInfo(url: fileUrl)
        } else if ViewHelper.isImage(url: fileUrl) {
            file = ImageFileInfo(url: fileUrl)
        } else {
            file = FileInfo(url: fileUrl)
        }
        
        fileInfos.append(file)
        fileIdDict[file.id] = file
    }
    
    private func updateSelectedFileUrls(_ idSet: Set<UUID>) -> Void {
        let selectedFileSet = idSet
            .map { fileIdDict[$0] }
            .filter { $0 != nil }
        selectedUrls = selectedFileSet.map({ $0!.url })
    }
    
}

struct FileListView_Previews: PreviewProvider {
    static var previews: some View {
        FileListView(rootDirUrl: URL(dirPathString: "."), selectedUrls: .constant([URL]()), searchText: .constant(""), searchScope: .constant(.currentDir))
    }
}
