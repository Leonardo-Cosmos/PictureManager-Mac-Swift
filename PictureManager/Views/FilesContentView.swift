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
    
    @State var runningSearchTask: Task<(), Never>?
    
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
            if let displayDir = filesState.displayDir {
                Self.sortFiles(dirFiles: &displayDir.files, state: filesState)
                refresh()
            }
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
                .help("Navigate to parent directory")
                .disabled(filesState.currentDir == filesState.rootDir)
            }
        }
    }
    
    @ViewBuilder private func createFilesView(switchDirAction: SwitchDirAction) -> some View {
        FilesDetailView(dir: $filesState.displayDir, selectionSet: $filesState.selectedIdSet, sortOrder: $filesState.sortOrder, refreshState: $refreshState)
            .onChange(of: isSearching) { isSearching in
                if isSearching {
                    searchFiles()
                } else {
                    dismissSearchFiles()
                    
                    if let currentDir = filesState.currentDir {
                        filesState.displayDir = currentDir
                        Task {
                            await loadFilesOfDirectory(dir: currentDir, state: filesState)
                            refresh()
                        }
                    }
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
            filesState.displayDir = rootDir
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
        filesState.selectedIdSet.removeAll()
        
        if isSearching {
            searchFiles()
        } else {
            filesState.displayDir = dir
            Task {
                await loadFilesOfDirectory(dir: dir, state: filesState)
                refresh()
            }
        }
    }

    private func loadFilesOfDirectory(dir: DirectoryInfo, state: FileCollectionState, recursive: Bool = false,
                                      searchMatcher: (any FileInfoMatcher)? = nil) async {
        guard let currentDir = state.currentDir else {
            return
        }
        
        Self.logger.debug("List files of directory \(currentDir.url.purePath), recursive: \(recursive)")       
        
        if recursive {
            state.displayDir?.files.removeAll()
            let loadFilePathsStream = FileUrlProvider.default.listDirecotryRecursively(dirPath: currentDir.url.purePath)
            for await (loadedDirPath, loadedFilePaths) in loadFilePathsStream {
                Self.logger.debug("Async loaded files count: \(loadedFilePaths.count), directory: \(loadedDirPath)")
                await Self.renderLoadedFiles(loadedFilePaths, loadedDirPath, state: state, isAsyncLoading: true, searchMatcher: searchMatcher)
            }
        } else {
            let loadedFilePaths = await FileUrlProvider.default.listDirectory(dirPath: currentDir.url.purePath)
            Self.logger.debug("Sync loaded files count: \(loadedFilePaths.count), directory: \(currentDir.url.purePath)")
            await Self.renderLoadedFiles(loadedFilePaths, currentDir.url.purePath, state: state, searchMatcher: searchMatcher)
        }
    }
    
    private static func renderLoadedFiles(_ loadedFilePaths: [String], _ loadedDirPath: String, state: FileCollectionState,
                                          isAsyncLoading: Bool = false, searchMatcher: (any FileInfoMatcher)? = nil) async {
        // When load asynchorously, loaded directory can be any subdirectory of current directory.
        // The corresponding DirectoryInfo instance of loaded directory should be created already.
        guard let loadedDir = isAsyncLoading ? state.loadedDirDict[loadedDirPath] : state.currentDir else {
            logger.error("Loaded diretory is not found, \(loadedDirPath)")
            return
        }
        
        await Self.createFilesAndLoadAttributes(loadedFilePaths: loadedFilePaths, loadedDir: loadedDir, state: state,                                                 isAsyncLoading: isAsyncLoading)
        
        if let displayDir = state.displayDir {
            Self.displayFilesAndSort(loadedFiles: loadedDir.files, displayDirFiles: &displayDir.files, state: state,
                                     isAsyncLoading: isAsyncLoading, searchMatcher: searchMatcher)
        }
    }
    
    /**
     Compares loaded directory contents and added files in directory to avoid re-add existing files.
     */
    private static func filterLoadedFiles(_ loadedFilePaths: [String], _ loadedDirFiles: inout [FileInfo], state: FileCollectionState,
                                            isAsyncLoading: Bool = false) -> [String] {
        let loadedFilePathSet = Set(loadedFilePaths)
        
        let existingFilePaths = loadedDirFiles.map { file in
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
        
        Self.logger.debug("Add loaded files count: \(addedFilePathSet.count)")
        
        if !isAsyncLoading {
            let removedFilePathSet = existingFilePathSet.subtracting(loadedFilePathSet)
            
            if !removedFilePathSet.isEmpty {
                let removedFiles = loadedDirFiles.filter({ file in removedFilePathSet.contains(file.url.purePath) })
                for removedFile in removedFiles {
                    state.removeFile(id: removedFile.id)
                }
                loadedDirFiles.removeAll(where: { file in removedFilePathSet.contains(file.url.purePath) })
                
                Self.logger.debug("Removed not loaded files count: \(removedFilePathSet.count)")
            }
        }
        
        return [String](addedFilePathSet)
    }
    
    /**
     Create instances of FileInfo and load attributes.
     */
    private static func createFilesAndLoadAttributes(loadedFilePaths: [String], loadedDir: DirectoryInfo, state: FileCollectionState,
                                                  isAsyncLoading: Bool = false) async {
        
        let addedFilePaths = Self.filterLoadedFiles(loadedFilePaths, &loadedDir.files, state: state, isAsyncLoading: isAsyncLoading)
        
        var addedFiles: [FileInfo] = []
        var file: FileInfo
        for filePath in addedFilePaths {
            guard let fileAttributes = try? FileSystemManager.default.attributes(filePath) else {
                continue
            }
            
            let fileType = FileSystemManager.type(attributes: fileAttributes)
            
            switch fileType {
            case FileAttributeType.typeDirectory:
                let newDir = DirectoryInfo(path: filePath, parent: loadedDir)
                state.loadedDirDict[filePath] = newDir
                file = newDir
            case FileAttributeType.typeRegular:
                if ViewHelper.isImage(path: filePath) {
                    file = ImageFileInfo(path: filePath, parent: loadedDir)
                } else {
                    file = RegularFileInfo(path: filePath, parent: loadedDir)
                }
            default:
                file = FileInfo(path: filePath, parent: loadedDir)
            }
            
            file.permissions = FileSystemManager.posixPermissions(attributes: fileAttributes)
            
            addedFiles.append(file)
        }
        
        loadedDir.files.append(contentsOf: addedFiles)
        
        await ViewHelper.loadUrlResourceValues(files: addedFiles)
    }
    
    private static func matchSearchCriteria(_ addedFiles: [FileInfo], _ displayDirFiles: inout [FileInfo], state: FileCollectionState,
                                            isAsyncLoading: Bool = false, fileMatcher: FileMatcher) -> [FileInfo] {
        
        // Remove files not matching search criteria.
        if !isAsyncLoading {
            let removedFiles = displayDirFiles.filter({ file in !fileMatcher(file) })
            if !removedFiles.isEmpty {
                var removedFileIdSet = Set<UUID>()
                
                for removedFile in removedFiles {
                    state.removeFile(id: removedFile.id)
                    removedFileIdSet.insert(removedFile.id)
                }
                displayDirFiles.removeAll(where: { file in removedFileIdSet.contains(file.id) })
                
                Self.logger.debug("Removed mismatched files count: \(removedFiles.count)")
            }
        }
        
        return addedFiles.filter({ file in fileMatcher(file) })
    }
    
    /**
     Adds files to view and sorts file list after add them.
     */
    private static func displayFilesAndSort(loadedFiles: [FileInfo], displayDirFiles: inout [FileInfo], state: FileCollectionState,
                                            isAsyncLoading: Bool = false, searchMatcher: (any FileInfoMatcher)? = nil) {
        
        var displayFiles: [FileInfo]
        if let fileInfoMatcher = searchMatcher {
            displayFiles = loadedFiles.filter({ file in fileInfoMatcher.match(file: file) })
        } else {
            displayFiles = loadedFiles
        }
        
        if !isAsyncLoading {
            Self.logger.debug("Remove all existing displaying files")
            displayDirFiles.removeAll()
        }
        
        Self.logger.debug("Add displaying files count: \(displayFiles.count)")
        
        displayDirFiles.append(contentsOf: displayFiles)
        for addedFile in displayFiles {
            state.addFile(addedFile)
        }
        
        sortFiles(dirFiles: &displayDirFiles, state: state)
    }
    
    private static func sortFiles(dirFiles: inout [FileInfo], state: FileCollectionState) {
        dirFiles.sort(using: state.sortOrder.first!)
    }
    
    private func updateSelectedFiles(isSearched: Bool = false) {
//        let state = isSearched ? searchedFilesState : filesState
        let state = filesState
        
        Self.logger.debug("Selected files count: \(state.selectedIdSet.count)")
        
        let newSelectedFiles = state.selectedIdSet
            .map { id in state.fileIdDict[id] }
            .filter { $0 != nil }
            .map { $0! }
        
        if newSelectedFiles.count < state.selectedIdSet.count {
            Self.logger.error("Selected files count: \(newSelectedFiles.count). Some selected file IDs cannot be converted FileInfo")
        }
        
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
                            
                            await Self.createFilesAndLoadAttributes(loadedFilePaths: [path], loadedDir: currentDir, state: filesState, isAsyncLoading: true)
                            Self.displayFilesAndSort(loadedFiles: currentDir.files, displayDirFiles: &filesState.displayDir!.files, state: filesState, searchMatcher: searchOption.matcher)
                            
                        }
                    }
                }
            }
        }
    }
    
    private func searchFiles() {
        dismissSearchFiles()
        
        if let currentDir = filesState.currentDir {
            filesState.displayDir = DirectoryInfo(url: currentDir.url)
            if searchOption.scope.isRecursive {
                runningSearchTask = Task {
                    await loadFilesOfDirectory(dir: currentDir, state: filesState, recursive: true, searchMatcher: searchOption.matcher)
                    refresh()
                }
            } else {
                runningSearchTask = Task {
                    await loadFilesOfDirectory(dir: currentDir, state: filesState, searchMatcher: searchOption.matcher)
                    refresh()
                }
            }
        }
    }
    
    private func dismissSearchFiles() {
        if let runningSearchTask = runningSearchTask {
            Self.logger.debug("Dismiss running search task")
            runningSearchTask.cancel()
        }
    }
}

struct SwitchDirAction {
    
    var action: (DirectoryInfo) -> Void
    
    init(_ switchAction: @escaping (DirectoryInfo) -> Void) {
        self.action = switchAction
    }
    
    func callAsFunction(dir: DirectoryInfo) {
        action(dir)
    }
}

struct FilesContentView_Previews: PreviewProvider {
    static var previews: some View {
        FilesContentView(rootDirUrl: URL(dirPathString: "."), selectedFiles: .constant([FileInfo]()), searchOption: SearchOption())
    }
}
