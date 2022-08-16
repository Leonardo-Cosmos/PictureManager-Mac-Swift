//
//  FileListView.swift
//  PictureManager
//
//  Created on 2021/10/17.
//

import SwiftUI

struct FileListView: View {
    
    let dirPath: URL
    
    enum SortBy: String, CaseIterable, Identifiable {
        case name = "name"
        case dateModified = "dateModified"
        case dateCreated = "dateCreated"
        case size = "size"
        
        var id: SortBy {
            return self
        }
    }
    
    enum ViewStyle: String, CaseIterable, Identifiable {
        case icon = "icon"
        case list = "list"
        
        var id: ViewStyle {
            return self
        }
    }
    
    @AppStorage("FileListView.sortBy")
    private var sortBy: SortBy = .name
    
    @AppStorage("FileListView.viewStyle")
    private var viewStyle: ViewStyle = .list
    
    @State var fileInfos = [FileInfo]()
    
    @State private var multiSelection = Set<UUID>()
    
    var body: some View {
        NavigationView {
            List(fileInfos, selection: $multiSelection) { file in
                NavigationLink() {
                    FileDetailView(fileUrl: file.url)
                } label: {
                    HStack {
                        if file.url.pathExtension == "jpg" {
                            Image(nsImage: NSImage(byReferencing: file.url))
                                .resizable()
                                .aspectRatio(contentMode: ContentMode.fit)
                                .frame(width: 64, height: 64)
                                .cornerRadius(5)
                        }
                        Text(file.name)
                    }
                }
                
            }
        }
        .navigationTitle(dirPath.lastPathComponent)
        .onAppear(perform: loadFiles)
    }
    
    private func loadFiles() {
        let filePaths = FileSystemManager.Default.filesOfDirectory(atPath: dirPath.path)
        print("List files of directory \(dirPath.path), number of files \(filePaths.count)")
        var fileInfos = filePaths.map { filePath in FileInfo(url: URL(fileURLWithPath: filePath)) }
        
        if sortBy == .name {
            fileInfos.sort { lFile, rFile in
                return lFile.url.path < rFile.url.path
            }
        }
        
        self.fileInfos = fileInfos
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
    
    private func switchToIconView() {
        
    }
    
    private func switchToListView() {
        
    }
}

struct FileListView_Previews: PreviewProvider {
    static var previews: some View {
        FileListView(dirPath: URL(fileURLWithPath: "."))
    }
}
