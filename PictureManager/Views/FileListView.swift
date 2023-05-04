//
//  FileListView.swift
//  PictureManager
//
//  Created on 2021/10/17.
//

import SwiftUI
import os

struct FileListView: View {
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
    
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
    
    @State private var fileIdDict = [UUID: FileInfo]()
    
    @State private var multiSelection = Set<UUID>()
    
    @State private var selectedFileUrl: URL? = nil
    
    var body: some View {
        HSplitView {
            List(fileInfos, selection: $multiSelection) { file in
                HStack {
                    if file.isImage {
                        Image(nsImage: NSImage(byReferencing: file.url))
                            .resizable()
                            .aspectRatio(contentMode: ContentMode.fit)
                            .frame(width: 64, height: 64)
                            .cornerRadius(5)
                    }
                    Text(file.name)
                }
                .onAppear {
                    if !file.loaded {
                        if ViewHelper.isImage(file.url) {
                            file.isImage = true
                        }
                        file.loaded = true
                    }
                }
            }
            .frame(minWidth: 100)
            .layoutPriority(1)
            .onChange(of: multiSelection, perform: { selections in
                if selections.count == 1, let fileInfo = fileIdDict[selections.first!] {
                    selectedFileUrl = fileInfo.url
                }
            })
            
            FileDetailView(fileUrl: selectedFileUrl)
                .frame(minWidth: 100, maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(dirPath.lastPathComponent)
        .onAppear(perform: loadFiles)
    }
    
    private func loadFiles() {
        Self.logger.debug("List files of directory \(dirPath.path)")
        
        var filePaths: [String]
        do {
            filePaths = try FileSystemManager.Default.filesOfDirectory(atPath: dirPath.path)
        } catch let error as NSError {
            Self.logger.error("Cannot list files. \(error)")
            return
        }
        
        Self.logger.debug("Number of files \(filePaths.count)")
        
        fileInfos.removeAll()
        fileIdDict.removeAll()
        
        filePaths.forEach { filePath in
            let fileInfo = FileInfo(url: URL(fileURLWithPath: filePath))
            fileInfos.append(fileInfo)
            fileIdDict[fileInfo.id] = fileInfo
        }
        
        if sortBy == .name {
            fileInfos.sort { lFile, rFile in
                return lFile.url.path < rFile.url.path
            }
        }
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
