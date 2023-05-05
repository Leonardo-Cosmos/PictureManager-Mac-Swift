//
//  DirectoryView.swift
//  PictureManager
//
//  Created on 2021/4/11.
//

import SwiftUI
import os

struct DirectoryTreeView: View {
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
    
    @AppStorage("FolderTreeView.folders")
    private var rootDirPaths: [String] = []
    
    @State private var rootDirs = [DirectoryInfo]()
    
    @State private var dirIdDict = [UUID: DirectoryInfo]()
    
    @State private var singleSelection: UUID?
    
    @State private var flag = false
    
    @Binding var selectedUrl: URL?
    
    private let defaultUuid: UUID = UUID()
    
    var body: some View {
        VStack {
            List(rootDirs, children: \.children, selection: $singleSelection) { dir in
                VStack {
                    Text(dir.name).font(.headline)
                    if let errorMessage = dir.errorMessage {
                        Text(errorMessage).font(.subheadline)
                    }
                }
            }
            .onChange(of: singleSelection, perform: { value in
                if let selectedDirId = value {
                    Self.logger.info("Selected directory ID: \(selectedDirId)")
                    loadSubDirs(id: selectedDirId)
                } else {
                    Self.logger.info("No directory selected")
                }
            })
            
            HStack {
                Button(action: addDir) {
                    Label("Add Folder", systemImage: "plus")
                }.help(Text("Add Folder"))
                
                Button(action: removeDir) {
                    Label("Remove Folder", systemImage: "minus")
                }.help(Text("Remove Folder"))
                
                Button(action: refreshDirTree) {
                    Label("Fresh Tree View", systemImage: "arrow.2.circlepath")
                }
            }.labelStyle(.iconOnly)
        }.onAppear(perform: loadRootDirPaths)
    }
    
    private func loadRootDirPaths() {
        rootDirPaths.forEach { dataString in
            
            if let bookmarkData = Data(base64Encoded: dataString) {
                var isStale = false
                do {
                    let dirUrl = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
                    
                    _ = dirUrl.startAccessingSecurityScopedResource()
                    rootDirs.append(createDirInfo(url: dirUrl))
                    dirUrl.stopAccessingSecurityScopedResource()
                    
                } catch let error as NSError {
                    Self.logger.error("Cannot resolve security-scoped bookmark: \(error)")
                }
            }
        }
    }
    
    private func createDirInfo(path: String, with consume: (DirectoryInfo) -> Void = { _ in return }) -> DirectoryInfo {
        let url = URL(fileURLWithPath: path, isDirectory: true)
        return createDirInfo(url: url, with: consume)
    }
    
    private func createDirInfo(url: URL, with consume: (DirectoryInfo) -> Void = { _ in return }) -> DirectoryInfo {
        let dir = DirectoryInfo(url: url)
        
        consume(dir)
        
        dirIdDict[dir.id] = dir
        Self.logger.debug("Added \(dir.url.path) to dictionary.")
        return dir
    }
    
    private func destroyDirInfo(id: UUID) -> Void {
        if let dir = dirIdDict[id] {
            if let subDirs = dir.children {
                for subDir in subDirs {
                    destroyDirInfo(id: subDir.id)
                }
            }
            
            dirIdDict.removeValue(forKey: id)
            Self.logger.debug("Removed \(dir.url.path) from dictionary.")
        }
    }
    
    private func addDir() {
        if let dirUrl = ViewHelper.openDirectoryPanel() {
            rootDirs.append(createDirInfo(url: dirUrl))
            Self.logger.log("Added root directory: \(dirUrl)")
            
            do {
                let bookmarkData = try dirUrl.bookmarkData()
                rootDirPaths.append(bookmarkData.base64EncodedString())
            } catch let error as NSError {
                Self.logger.error("Cannot create security-scoped bookmark: \(error)")
            }
        }
    }
    
    private func removeDir() {
        if let selectedDirId = singleSelection {
            if rootDirs.contains(where: { dir in dir.id == selectedDirId}) {
                destroyDirInfo(id: selectedDirId)
                if let index = rootDirs.firstIndex(where: { dir in dir.id == selectedDirId}) {
                    let dirName = rootDirs[index].name
                    Self.logger.log("Removed root directory: \(dirName)")
                    rootDirs.remove(at: index)
                    rootDirPaths.remove(at: index)
                }
            } else {
                Self.logger.info("Selected directory isn't on root level, it won't be removed.")
            }
        }
    }
    
    private func refreshDirTree() {
        rootDirs.append(DirectoryInfo(url: URL(fileURLWithPath: ".")))
        rootDirs.removeLast()
    }
    
    func loadSubDirs(id: UUID) -> Void {
        guard let selectedDir = dirIdDict[id] else {
            return
        }
        
        self.selectedUrl = selectedDir.url
        
        Self.logger.debug("List subdirectories of: \(selectedDir.url.lastPathComponent)")
        
        if selectedDir.children == nil {
            selectedDir.children = []
            
            do {
                var subDirs = try FileSystemManager.Default.directoriesOfDirectory(atPath: selectedDir.url.path)
                subDirs.sort(by: <)
                
                for subDir in subDirs {
                    selectedDir.children!.append(createDirInfo(path: subDir))
                }
                
            } catch let error as NSError {
                Self.logger.error("Cannot list subdirectories. \(error)")
                selectedDir.errorMessage = "Cannot load"
            }
            
            refreshDirTree()
        }
    }
}

struct NodeView: View {
    var node: DirectoryInfo
    @Binding var selectedNode: DirectoryInfo?
    
    var body: some View {
        HStack {
            Text(node.name)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedNode = node
            do {
                let subDirs = try FileSystemManager.Default.directoriesOfDirectory(atPath: node.url.path)
                for subDir in subDirs {
                    node.children = []
                    node.children!.append(DirectoryInfo(url: URL(fileURLWithPath: subDir, isDirectory: true)))
                }
            } catch let error as NSError {
                print("Cannot list subdirectories. \(error)")
            }
        }
    }
}

struct DirectoryTreeView_Previews: PreviewProvider {
    static var previews: some View {
        DirectoryTreeView(selectedUrl: .constant(URL(fileURLWithPath: ".")))
    }
}
