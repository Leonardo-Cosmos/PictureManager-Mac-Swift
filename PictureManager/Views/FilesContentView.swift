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

struct FilesContentView: View {
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
    
    /**
     Root directory is the one selected in directory tree view and is the root in those file views displaying directory hierarchy.
     */
    var rootDirUrl: URL?
    
    @Binding var selectedFiles: [FileInfo]
    
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
    
    @State private var refreshState = false
    
    var body: some View {
        let switchDirAction = SwitchDirAction(switchDir)
        
        VStack(spacing: 0) {
            FilesDetailView(dir: $filesState.currentDir, selectionSet: $filesState.selectedIdSet, sortOrder: $filesState.sortOrder, refreshState: $refreshState)
                .navigationTitle(filesState.currentDir?.url.lastPathComponent ?? "")
                .environment(\.SwitchFilesViewDir, switchDirAction)
            
            Divider()
            
            PathBar(directory: $filesState.currentDir)
                .environment(\.SwitchFilesViewDir, switchDirAction)
        }
        .onChange(of: rootDirUrl) { dirUrl in
            Task {
                await loadRootDir(dirUrl: dirUrl)
            }
        }
        .onChange(of: filesState.selectedIdSet) { _ in
            updateSelectedFiles()
        }
        .onChange(of: filesState.sortOrder) { _ in
            sortFiles(dir: filesState.currentDir, state: filesState)
            refresh()
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
                            if let currentDir = filesState.currentDir {
                                Task {
                                    await addFiles(filePaths: [path], dir: currentDir, state: filesState)
                                }
                            }
                        } catch let error {
                            Self.logger.error("Cannot paste file, \(error.localizedDescription)")
                        }
                    }
                }
            }
        })
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    Task {
                        await switchDir(dir: filesState.currentDir?.parent)
                    }
                }, label: {
                    Image(systemName: "chevron.up")
                })
                .disabled(filesState.currentDir == filesState.rootDir)
            }
        }
        
//        if isSearching {
//            FilesDetailView(fileInfos: $searchedFilesState.rootDir.files, selectionSet: $searchedFilesState.selectedIdSet, sortOrder: $searchedFilesState.sortOrder)
//                .navigationTitle("Searching \(rootDirUrl?.lastPathComponent ?? "")")
//                .onChange(of: searchedFilesState.selectedIdSet) { _ in
//                    updateSelectedFiles(isSearched: true)
//                }
//                .onChange(of: searchOption.pattern) { _ in
//                    searchFiles()
//                }
//                .onChange(of: searchOption.scope) { _ in
//                    searchFiles()
//                }
//                .onCutCommand(perform: cutSelectedUrls)
//                .onCopyCommand(perform: copySelectedUrls)
//        } else {
            
                
//        }
    }
    
    private func refresh() {
//        refreshState.toggle()
        filesState.objectWillChange.send()
    }
    
    private func loadRootDir(dirUrl: URL?) async {
        filesState.clear()
        searchedFilesState.clear()
        
        guard let dirUrl = dirUrl else {
            return
        }
        
        if filesState.sortOrder.isEmpty {
            if sortBy == .name {
                filesState.sortOrder.append(SortDescriptor<FileInfo>(\.name))
            }
        }
        
        let rootDir = DirectoryInfo(url: dirUrl, parent: nil)
        await loadFilesOfDirectory(dir: rootDir, state: filesState)
        filesState.rootDir = rootDir
        filesState.currentDir = rootDir
        
        refresh()
    }
    
    private func switchDir(dir: DirectoryInfo?) async {
        guard let dir = dir else {
            return
        }
        
        await loadFilesOfDirectory(dir: dir, state: filesState)
        filesState.currentDir = dir
        refresh()
    }

    private func loadFilesOfDirectory(dir: DirectoryInfo, state: FileCollectionState) async {

        Self.logger.debug("List files of directory \(dir.url.purePath)")
        
        let loadFilesResult = await Task(priority: .userInitiated) { () throws -> [String] in
            return try FileSystemManager.default.filesOfDirectory(dirPath: dir.url.purePath)
        }.result
        
        var loadedFilePaths: [String]
        do {
            loadedFilePaths = try loadFilesResult.get()
        } catch let error as NSError {
            Self.logger.error("Cannot list files. \(error)")
            return
        }
        
        let loadedFilePathSet = Set(loadedFilePaths)
        
        let existingFilePaths = dir.files.map { file in
            if file is DirectoryInfo && file.url.purePath.last == "/" {
                var path = file.url.purePath
                path.removeLast()
                return path
            } else {
                return file.url.purePath
            }
        }
        let existingFilePathSet = Set(existingFilePaths)
        
        let addedFilePathSet = loadedFilePathSet.subtracting(existingFilePathSet)
        let removedFilePathSet = existingFilePathSet.subtracting(loadedFilePathSet)
        
        dir.files.removeAll(where: { file in removedFilePathSet.contains(file.url.purePath) })
        
        let addedFilePaths = [String](addedFilePathSet)

        await addFiles(filePaths: addedFilePaths, dir: dir, state: state)
    }
    
    private func addFiles(filePaths: [String], dir: DirectoryInfo, state: FileCollectionState) async {
                        
        var addedFiles: [FileInfo] = []
        var file: FileInfo
        for filePath in filePaths {
            guard let fileAttributes = try? FileSystemManager.default.attributes(filePath) else {
                continue
            }
            
            let fileType = FileSystemManager.type(attributes: fileAttributes)
            
            switch fileType {
            case FileAttributeType.typeDirectory:
                file = DirectoryInfo(path: filePath, parent: dir)
            case FileAttributeType.typeRegular:
                if ViewHelper.isImage(path: filePath) {
                    file = ImageFileInfo(path: filePath, parent: dir)
                } else {
                    file = RegularFileInfo(path: filePath, parent: dir)
                }
            default:
                file = FileInfo(path: filePath, parent: dir)
            }
            
            file.permissions = FileSystemManager.posixPermissions(attributes: fileAttributes)
            
            state.fileIdDict[file.id] = file
            addedFiles.append(file)
        }
        
        await ViewHelper.loadUrlResourceValues(files: addedFiles)
        
        dir.files.append(contentsOf: addedFiles)
        Self.logger.debug("Added file count: \(addedFiles.count), total file count: \(dir.files.count)")
        
        sortFiles(dir: dir, state: state)
    }
    
    private func sortFiles(dir: DirectoryInfo?, state: FileCollectionState) {
        dir?.files.sort(using: filesState.sortOrder.first!)
    }
    
    private func updateSelectedFiles(isSearched: Bool = false) {
        let state = isSearched ? searchedFilesState : filesState
        
        let newSelectedFiles = state.selectedIdSet
            .map { id in state.fileIdDict[id] }
            .filter { $0 != nil }
            .map { $0! }
        
        let newSelectedFileSet = Set(newSelectedFiles)
        let oldSelectedFileSet = Set(selectedFiles)
        
        let removedFileSet = oldSelectedFileSet.subtracting(newSelectedFileSet)
        let addedFileSet = newSelectedFileSet.subtracting(oldSelectedFileSet)
        
        selectedFiles.removeAll { url in removedFileSet.contains(url) }
        selectedFiles.append(contentsOf: addedFileSet)
    }
    
    private func cutSelectedUrls() -> [NSItemProvider] {
        let providers = selectedFiles.map { file in ViewHelper.urlToNSItemProvider(file.url) }
        Self.logger.debug("Cut file count: \(providers.count)")
        return providers
    }
    
    private func copySelectedUrls() -> [NSItemProvider] {
        let providers = selectedFiles.map { file in ViewHelper.urlToNSItemProvider(file.url) }
        Self.logger.debug("Copied file count: \(providers.count)")
        return providers
    }
    
    private func searchFiles() {
        Self.logger.info("Searching pattern: \(searchOption.pattern), in: \(searchOption.scope.rawValue), of: \(searchOption.matchingTarget.rawValue), by: \(searchOption.matchingMethod.rawValue)")
        
        searchedFilesState.clear()
        
        let recursive = searchOption.scope == .currentDirRecursively || searchOption.scope == .rootDirRecursively
        
//        if let rootDirUrl = rootDirUrl {
//            FileUrlProvider.default.listDirectory(dirUrl: rootDirUrl, options: FileUrlProvider.ListDirectoryOption(fileType: .all, recursive: recursive,
//                update: { urls in
//                    let paths = urls.map { $0.purePath }
//                    DispatchQueue.main.async {
//                        addFiles(filePaths: paths, isSearched: true)
//                    }
//                },
//                complete: { (_, error) in
//                    if let error = error {
//                        Self.logger.error("Search file error: \(error)")
//                    }
//                },
//                match: { url in
//                    return url.lastPathComponent.contains(searchOption.pattern)
//                }
//            ))
//        }
    }
}

struct SwitchDirAction {
    
    var switchAction: (DirectoryInfo) async -> Void
    
    init(_ switchAction: @escaping (DirectoryInfo) async -> Void) {
        self.switchAction = switchAction
    }
    
    func callAsFunction(dir: DirectoryInfo) {
        Task {
            await switchAction(dir)
        }
    }
}

struct FilesContentView_Previews: PreviewProvider {
    static var previews: some View {
        FilesContentView(rootDirUrl: URL(dirPathString: "."), selectedFiles: .constant([FileInfo]()), searchOption: SearchOption())
    }
}
