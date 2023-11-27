//
//  FileTreeView.swift
//  PictureManager
//
//  Created on 2023/10/18.
//

import SwiftUI
import os

struct FilesDetailView: View {
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
    
    let invalidValue = "--"
    
    @Binding var dir: DirectoryInfo?
    
    @Binding var selectionSet: Set<UUID>
    
    @Binding var sortOrder: [SortDescriptor<FileInfo>]
    
    @Binding var refreshState: Bool
    
    @Environment(\.SwitchFilesViewDir) private var switchDir: SwitchDirAction
    
    var body: some View {
        Table(dir?.files ?? [], selection: $selectionSet, sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name) { file in
                HStack {
                    FileThumbnailView(thumbnail: file.thumbnail, isDirectory: file is DirectoryInfo)
                    Text(file.name)
                }
                .onAppear {
                    if !file.thumbnail.requested {
                        ViewHelper.loadThumbnail(file: file)
                        file.thumbnail.requested = true
                    }
                }
                .onDoubleClick {
                    if let dir = file as? DirectoryInfo {
                        switchDir(dir: dir)
                    }
                }
            }
            
            TableColumn("Date Modified", value: \.contentModificationDate) { file in
                Text(file.contentModificationDate?.formatted() ?? invalidValue)
            }
            
            TableColumn("Date Created", value: \.creationDate) { file in
                Text(file.creationDate?.formatted() ?? invalidValue)
            }
            
            TableColumn("Date Last Opened", value: \.contentAccessDate) { file in
                Text(file.contentAccessDate?.formatted() ?? invalidValue)
            }
            
            TableColumn("Date Added", value: \.addedToDirectoryDate) { file in
                Text(file.addedToDirectoryDate?.formatted() ?? invalidValue)
            }
            
            TableColumn("Date Attribute Modified", value: \.addedToDirectoryDate) { file in
                Text(file.attributeModificationDate?.formatted() ?? invalidValue)
            }
        }
        .onChange(of: sortOrder) { sortOrder in
            print("\(sortOrder)")
        }
    }
    
    func triggerRefresh() {
        refreshState.toggle()
    }
}

struct FilesDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FilesDetailView(dir: .constant(DirectoryInfo(path: ".")), selectionSet: .constant(Set<UUID>()), sortOrder: .constant([SortDescriptor<FileInfo>(\.name)]), refreshState: .constant(false))
    }
}
