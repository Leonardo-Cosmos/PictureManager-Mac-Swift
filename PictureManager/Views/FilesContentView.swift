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
    
    typealias FileMatcher = (FileInfo) -> Bool
    
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
    private var isSearching: Bool
    
    @StateObject private var searchedFilesState = FileCollectionState()
    
    @State private var refreshState = false
    
    var body: some View {
        let switchDirAction = SwitchDirAction(switchDir)
        
        VStack(spacing: 0) {
            createFilesView(switchDirAction: switchDirAction)
            
            Divider()
            
            PathBar(directory: $filesState.currentDir)
                .environment(\.SwitchFilesViewDir, switchDirAction)
        }
        .onChange(of: rootDirUrl, perform: loadRootDir)
        .onChange(of: filesState.selectedIdSet) { _ in
            updateSelectedFiles()
        }
        .onChange(of: filesState.sortOrder) { _ in
            Self.sortFiles(dir: filesState.currentDir, state: filesState)
            refresh()
        }
        .onCutCommand(perform: cutSelectedUrls)
        .onCopyCommand(perform: copySelectedUrls)
        .onPasteCommand(of: [UTType.fileListPath.identifier], validator: validatePastedUrls, perform: pasteUrls)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    switchDir(dir: filesState.currentDir?.parent)
                }, label: {
                    Image(systemName: "chevron.up")
                })
                .disabled(filesState.currentDir == filesState.rootDir)
            }
        }
    }
    
    @ViewBuilder private func createFilesView(switchDirAction: SwitchDirAction) -> some View {
        FilesDetailView(dir: $filesState.currentDir, selectionSet: $filesState.selectedIdSet, sortOrder: $filesState.sortOrder, refreshState: $refreshState)
            .onChange(of: isSearching) { isSearching in
                if isSearching {
                    searchFiles()
                } else {
                    dismissSearchFiles()
                }
            }
            .onChange(of: searchOption.refreshState) { _ in
                searchFiles()
            }
            .navigationTitle(filesState.currentDir?.url.lastPathComponent ?? "")
            .environment(\.SwitchFilesViewDir, switchDirAction)
    }
    
    private func refresh() {
//        refreshState.toggle()
        filesState.objectWillChange.send()
    }
    
    private func loadRootDir(dirUrl: URL?) {
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
        filesState.rootDir = rootDir
        filesState.currentDir = rootDir
        
        if isSearching {
            searchFiles()
        } else {
            Task {
                await loadFilesOfDirectory(dir: rootDir, state: filesState)
            }
        }
        
        refresh()
    }
    
    private func switchDir(dir: DirectoryInfo?) {
        guard let dir = dir else {
            return
        }
        
        filesState.currentDir = dir
        
        if isSearching {
            searchFiles()
        } else {
            Task {
                await loadFilesOfDirectory(dir: dir, state: filesState)
                refresh()
            }
        }
    }

    private func loadFilesOfDirectory(dir: DirectoryInfo, state: FileCollectionState, recursive: Bool = false, searchMatcher: (any FileInfoMatcher)? = nil) async {

        Self.logger.debug("List files of directory \(dir.url.purePath)")
        
        if recursive {
            let loadFilePathsStream = FileUrlProvider.default.listDirecotryRecursively(dirPath: dir.url.purePath)
            for await loadedFilePaths in loadFilePathsStream {
                await Self.addLoadedFiles(loadedFilePaths, dir: dir, state: state)
            }
        } else {
            let loadedFilePaths = await FileUrlProvider.default.listDirectory(dirPath: dir.url.purePath)
            await Self.addLoadedFiles(loadedFilePaths, dir: dir, state: state)
        }
    }
    
    private static func addLoadedFiles(_ loadedFilePaths: [String], dir: DirectoryInfo, state: FileCollectionState, searchMatcher: (any FileInfoMatcher)? = nil) async {
        let addedFilePaths = Self.filterExistingFiles(loadedFilePaths, dir: dir, state: state)
        
        if let fileInfoMatcher = searchMatcher {
            await Self.addFilesandLoadAttributes(filePaths: addedFilePaths, dir: dir, state: state, fileMatcher: { file in
                fileInfoMatcher.match(file: file)
            })
        } else {
            await Self.addFilesandLoadAttributes(filePaths: addedFilePaths, dir: dir, state: state)
        }
    }
    
    /**
     Compares loaded directory contents and existing files in directory to avoid re-add existing files.
     */
    private static func filterExistingFiles(_ loadedFilePaths: [String], dir: DirectoryInfo, state: FileCollectionState) -> [String] {
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
        
        if !removedFilePathSet.isEmpty {
            let removedFiles = dir.files.filter({ file in removedFilePathSet.contains(file.url.purePath) })
            for removedFile in removedFiles {
                state.removeFile(id: removedFile.id)
            }
            dir.files.removeAll(where: { file in removedFilePathSet.contains(file.url.purePath) })
        }
        
        return [String](addedFilePathSet)
    }
    
    /**
     Load file attributes and filter.
     */
    private static func addFilesandLoadAttributes(filePaths: [String], dir: DirectoryInfo, state: FileCollectionState, fileMatcher: FileMatcher? = nil) async {
                        
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
            
            addedFiles.append(file)
        }
        
        await ViewHelper.loadUrlResourceValues(files: addedFiles)
        
        if let fileMatcher = fileMatcher {
            addedFiles = matchSearchCriteria(addedFiles, dir: dir, state: state, fileMatcher: fileMatcher)
        }
        
        addFilesAndSort(addedFiles, dir: dir, state: state)
    }
    
    private static func matchSearchCriteria(_ addedFiles: [FileInfo], dir: DirectoryInfo, state: FileCollectionState, fileMatcher: FileMatcher) -> [FileInfo] {
        
        // Remove files not matching search criteria.
        var removedFiles = dir.files.filter({ file in !fileMatcher(file) })
        if !removedFiles.isEmpty {
            var removedFileIdSet = Set<UUID>()
            
            for removedFile in removedFiles {
                state.removeFile(id: removedFile.id)
                removedFileIdSet.insert(removedFile.id)
            }
            dir.files.removeAll(where: { file in removedFileIdSet.contains(file.id) })
            
//            Self.logger.debug("Removed files: \(removedFiles.count)")
        }
        
        return addedFiles.filter({ file in fileMatcher(file) })
    }
    
    /**
     Adds files to view and sorts file list after add them.
     */
    private static func addFilesAndSort(_ addedFiles: [FileInfo], dir: DirectoryInfo, state: FileCollectionState) {
        dir.files.append(contentsOf: addedFiles)
        for addedFile in addedFiles {
            state.addFile(addedFile)
        }
        
//        Self.logger.debug("Added files: \(addedFiles.count)")
        
        sortFiles(dir: dir, state: state)
    }
    
    private static func sortFiles(dir: DirectoryInfo?, state: FileCollectionState) {
        dir?.files.sort(using: state.sortOrder.first!)
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
    
    private func validatePastedUrls(providers: [NSItemProvider]) -> [NSItemProvider]? {
        guard rootDirUrl != nil else {
            return nil
        }
        return providers
    }
    
    private func pasteUrls(providers: [NSItemProvider]) {
        for provider in providers {
            ViewHelper.pathFromNSItemProvider(provider) { (path, error) in
                if let error = error {
                    Self.logger.error("Cannot load pasted path, \(error.localizedDescription)")
                } else  if let path = path {
                    // TODO: add pasted file together.
                    if let currentDir = filesState.currentDir {
                        Task {
                            do {
                                let filePath = FilePath(path)
                                try FileSystemManager.default.copyFile(filePath.lastComponent!.string, from: filePath.removingLastComponent().string, to: currentDir.url.purePath)
                                
                            } catch let error {
                                Self.logger.error("Cannot paste file, \(error.localizedDescription)")
                            }
                            
                            await Self.addFilesandLoadAttributes(filePaths: [path], dir: currentDir, state: filesState)
                        }
                    }
                }
            }
        }
    }
    
    private func searchFiles() {
        if let currentDir = filesState.currentDir {
            if searchOption.scope.isRecursive {
                Task {
                    await loadFilesOfDirectory(dir: currentDir, state: filesState, recursive: true, searchMatcher: searchOption.matcher)
                    refresh()
                }
            } else {
                Task {
                    await loadFilesOfDirectory(dir: currentDir, state: filesState, searchMatcher: searchOption.matcher)
                    refresh()
                }
            }
        }
    }
    
    private func dismissSearchFiles() {
        if let currentDir = filesState.currentDir {
            Task {
                await loadFilesOfDirectory(dir: currentDir, state: filesState)
                refresh()
            }
        }
    }
}

struct SwitchDirAction {
    
    var switchAction: (DirectoryInfo) -> Void
    
    init(_ switchAction: @escaping (DirectoryInfo) -> Void) {
        self.switchAction = switchAction
    }
    
    func callAsFunction(dir: DirectoryInfo) {
        switchAction(dir)
    }
}

struct FilesContentView_Previews: PreviewProvider {
    static var previews: some View {
        FilesContentView(rootDirUrl: URL(dirPathString: "."), selectedFiles: .constant([FileInfo]()), searchOption: SearchOption())
    }
}
