//
//  DirectoryView.swift
//  PictureManager
//
//  Created on 2021/4/11.
//

import SwiftUI

struct DirectoryTreeView: View {
    
    @State var rootDirs = [DirectoryInfo]()
    
    @State var dirIdDict = [UUID: DirectoryInfo]()
    
    @State private var singleSelection: UUID?
    
    @State var flag = false
    
    private let defaultUuid: UUID = UUID()
    
    var body: some View {
        
        VStack {
            List(rootDirs, children: \.children, selection: $singleSelection) { dir in
                NavigationLink(destination: FileListView(dirPath: dir.url))
                {
                    Text(dir.name).font(.subheadline)
                }
            
            }
            .onChange(of: singleSelection, perform: { value in
                if let selectedDirId = value {
                    print("Changed directory selection: \(selectedDirId)")
                    onDirSelected(id: selectedDirId)
                } else {
                    print("No directory selected")
                }
            })
            
//            Text("\(singleSelection ?? defaultUuid) selections")
            
//            TextField("Eneter:", text: $name)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .onChange(of: name) { newValue in
//                    print("Name changed to \(name)")
//                }
            
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
        print("Added \(dir.url) to dictionary.")
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
            print("Removed \(dir.url.path) from dictionary.")
        }
    }
    
    private func addDir() {
        if let dirUrl = FileSystemManager.openDirectoryPanel() {
            self.rootDirs.append(createDirInfo(url: dirUrl))
        }
    }
    
    private func removeDir() {
        if let selectedDirId = singleSelection {
            if self.rootDirs.contains(where: { dir in dir.id == selectedDirId}) {
                destroyDirInfo(id: selectedDirId)
                self.rootDirs.removeAll { dir in dir.id == selectedDirId }
            } else {
                print("Selected directory isn't on root level, it won't be removed.")
            }
        }
    }
    
    private func refreshDirTree() {
        rootDirs.append(DirectoryInfo(url: URL(fileURLWithPath: ".")))
        rootDirs.removeLast()
    }
    
    func onDirSelected(id: UUID) -> Void {
        if let selectedDir = dirIdDict[id] {
            print("Selected directory path: \(selectedDir.url.path)")
            if selectedDir.children == nil {
                selectedDir.children = []
                
                let subDirs = FileSystemManager.Default.directoriesOfDirectory(atPath: selectedDir.url.path)
                for subDir in subDirs {
                    selectedDir.children!.append(createDirInfo(path: subDir))
                }
                
                print("Appended sub directories of \(selectedDir.url.path)")
                
                refreshDirTree()
            }
        }
    }
}

struct DirectoryTreeView_Previews: PreviewProvider {
    static var previews: some View {
        DirectoryTreeView()
    }
}
