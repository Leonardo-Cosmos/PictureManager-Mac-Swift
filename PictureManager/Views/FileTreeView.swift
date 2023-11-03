//
//  FileTreeView.swift
//  PictureManager
//
//  Created on 2023/10/18.
//

import SwiftUI
import os

struct FileTreeView: View {
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
    
    @Binding var fileInfos: [FileInfo]
    
    @Binding var selectionSet: Set<UUID>
    
    @State private var sortOrder = [SortDescriptor<FileInfo>(\.name, comparator: .localizedStandard)]
    
    var body: some View {
        Table(fileInfos, selection: $selectionSet, sortOrder: $sortOrder) {
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
            }
        
            TableColumn("Date Created", value: \.creationDate) { file in
                Text(file.creationDate?.formatted() ?? "--")
            }
        }.onChange(of: sortOrder) { sortOrder in
            print("\(sortOrder)")
        }
    }
}

struct FileGridView_Previews: PreviewProvider {
    static var previews: some View {
        FileTreeView(fileInfos: .constant([FileInfo]()), selectionSet: .constant(Set<UUID>()))
    }
}
