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
            FileTreeView(fileInfos: $searchedFiles, selectionSet: $searchedSelectedIdSet, loadImage: loadImage)
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
            FileTreeView(fileInfos: $fileInfos, selectionSet: $selectedIdSet, loadImage: loadImage)
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
                                    try FileSystemManager.default.copyFile(fileUrl.lastPathComponent, from: fileUrl.deletingLastPathComponent().path, to: rootDirUrl!.path)
                                    addFile(filePath: fileUrl.path)
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

        Self.logger.debug("List files of directory \(dirUrl.path)")

        var filePaths: [String]
        do {
            filePaths = try FileSystemManager.default.filesOfDirectory(atPath: dirUrl.path)
        } catch let error as NSError {
            Self.logger.error("Cannot list files. \(error)")
            return
        }

        Self.logger.debug("Number of files \(filePaths.count)")

        filePaths.forEach(addFile)

        if sortBy == .name {
            fileInfos.sort { lFile, rFile in
                return lFile.url.path < rFile.url.path
            }
        }
    }
    
    private func addFile(filePath: String) {
        let fileInfo = FileInfo(url: URL(fileURLWithPath: filePath))
        fileInfos.append(fileInfo)
        fileIdDict[fileInfo.id] = fileInfo
    }
    
    private func updateSelectedFileUrls(_ idSet: Set<UUID>) -> Void {
        let selectedFileSet = idSet
            .map { fileIdDict[$0] }
            .filter { $0 != nil }
        selectedUrls = selectedFileSet.map({ $0!.url })
    }
    
    @ViewBuilder private func createItem(file: FileInfo) -> some View {
        switch viewStyle {
        case .icon:
            HStack {
                if file.url.pathExtension == "jpg" {
                    AsyncImage(url: file.url) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }.frame(width: 128, height: 128)
                }
                Text(file.name)
            }
        case .list:
            VStack {
                if file.url.pathExtension == "jpg" {
                    Image(nsImage: NSImage(byReferencing: file.url))
                        .resizable()
                        .frame(width: 64, height: 64)
                }
                Text(file.name)
            }
        }
    }

    private func loadImage(file: FileInfo) {
        let fileUrl = file.url

        if !ViewHelper.isImage(fileUrl) {
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            guard let nsImage = NSImage(contentsOf: fileUrl) else {
                return
            }

            DispatchQueue.main.async {
                file.image = Image(nsImage: nsImage)
            }
        }
    }
}

struct ImageView: View {
    
    let imageLength: Double = 64
    
    @ObservedObject var file: FileInfo
    
    var body: some View {
        if let image = file.image {
            image
                .resizable()
                .aspectRatio(contentMode: ContentMode.fit)
                .frame(width: imageLength, height: imageLength)
                .cornerRadius(5)
        }
    }
}

struct FileListView_Previews: PreviewProvider {
    static var previews: some View {
        FileListView(rootDirUrl: URL(fileURLWithPath: "."), selectedUrls: .constant([URL]()), searchText: .constant(""), searchScope: .constant(.currentDir))
    }
}
