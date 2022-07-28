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
    
    @State var files = [FileInfo]()
    
    var body: some View {
        List(files) { file in
            createItem(file: file)
        }
        .toolbar {
            ToolbarItem {
                Button(action: switchToListView) {
                    Label("List", systemImage: "list.bullet")
                }
            }
        }
        .navigationTitle(dirPath.lastPathComponent)
        .onAppear(perform: self.loadFiles)
    }
    
    private func loadFiles() {
        let files = FileSystemManager.Default.filesOfDirectory(atPath: dirPath.path)
        print("List files of directory \(dirPath.path), number of files \(files.count)")
        self.files = files.map { file in FileInfo(url: URL(fileURLWithPath: file)) }
    }
    
    @ViewBuilder private func createItem(file: FileInfo) -> some View {
        switch viewStyle {
        case .icon:
            HStack {
                if file.url.pathExtension == "jpg" {
                    AsyncImage(url: file.url)
                        .frame(width: 128, height: 128)
                }
                Text(file.name)
            }
        case .list:
            VStack {
                if file.url.pathExtension == "jpg" {
                    AsyncImage(url: file.url) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
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
        FileListView(dirPath: URL(fileURLWithPath: "/Users/Leonardo"))
    }
}
