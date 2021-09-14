//
//  DirectoryView.swift
//  PictureManager
//
//  Created on 2021/4/11.
//

import SwiftUI

struct DirectoryView: View {
    
    @State var rootDirs = [DirectoryInfo]()
    
    @State var dirIdDict = [UUID: DirectoryInfo]()
    
    @State private var singleSelection: UUID?
    
    @State var flag = false
    
    private let defaultUuid: UUID = UUID()
    
    var body: some View {
        
        VStack {
            List(rootDirs, children: \.children, selection: $singleSelection) { node in
                NavigationLink(destination: /*@START_MENU_TOKEN@*/Text("Destination")/*@END_MENU_TOKEN@*/)
                {
                    Text(node.name).font(.subheadline)
                }
            
            }.navigationTitle("Folders")
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
                Button("➕") {
                    if let dirUrl = FileSystemManager.openDirectoryPanel() {
                        self.rootDirs.append(createDirInfo(url: dirUrl))
                    }
                }.help(Text("Add directory"))
                
                Button("➖") {
                    if let selectedDirId = singleSelection {
                        if self.rootDirs.contains(where: { dir in dir.id == selectedDirId}) {
                            destroyDirInfo(id: selectedDirId)
                            self.rootDirs.removeAll { dir in dir.id == selectedDirId }
                        } else {
                            print("Selected directory isn't on root level, it won't be removed.")
                        }
                    }
                }.help(Text("Remove directory"))
                
                Button("🔄") {
                    rootDirs.append(DirectoryInfo(url: URL(fileURLWithPath: ".")))
                    rootDirs.removeLast()
                }
            }
        }
    }
    
    func createDirInfo(path: String, with consume: (DirectoryInfo) -> Void = { _ in return }) -> DirectoryInfo {
        let url = URL(fileURLWithPath: path, isDirectory: true)
        return createDirInfo(url: url, with: consume)
    }
    
    func createDirInfo(url: URL, with consume: (DirectoryInfo) -> Void = { _ in return }) -> DirectoryInfo {
        let dir = DirectoryInfo(url: url)
        
        consume(dir)
        
        dirIdDict[dir.id] = dir
        print("Added \(dir.url) to dictionary.")
        return dir
    }
    
    func destroyDirInfo(id: UUID) -> Void {
        if let dir = dirIdDict[id] {
            if let subDirs = dir.children {
                for subDir in subDirs {
                    destroyDirInfo(id: subDir.id)
                }
            }
            
            dirIdDict.removeValue(forKey: id)
            print("Removed \(dir.url) from dictionary.")
        }
    }
    
    func onDirSelected(id: UUID) -> Void {
        if let selectedDir = dirIdDict[id] {
            print("Selected directory path: \(selectedDir.url).")
            if selectedDir.children == nil {
                selectedDir.children = []
                
                let subDirs = FileSystemManager.Default.directoriesOfDirectory(atPath: selectedDir.url.path)
                for subDir in subDirs {
                    selectedDir.children!.append(createDirInfo(path: subDir))
                }
                
                print("Appended sub directories of \(selectedDir.url).")
            }
        }
    }
}

struct DirectoryView_Previews: PreviewProvider {
    static var previews: some View {
        DirectoryView()
    }
}
