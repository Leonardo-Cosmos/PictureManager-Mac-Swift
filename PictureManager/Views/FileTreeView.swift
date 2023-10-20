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
    
    var body: some View {
        List(fileInfos, selection: $selectionSet) { file in
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
    }
}

struct FileGridView_Previews: PreviewProvider {
    static var previews: some View {
        FileTreeView(fileInfos: .constant([FileInfo]()), selectionSet: .constant(Set<UUID>()))
    }
}
