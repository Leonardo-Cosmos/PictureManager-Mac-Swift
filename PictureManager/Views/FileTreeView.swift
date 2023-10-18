//
//  FileTreeView.swift
//  PictureManager
//
//  Created on 10/18/23.
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
    
    let loadImage: ((FileInfo) -> Void)?
    
    var body: some View {
        List(fileInfos, selection: $selectionSet) { file in
            HStack {
                ImageView(file: file)
                Text(file.name)
            }
            .onAppear {
                if !file.loaded {
                    loadImage?(file)
                    file.loaded = true
                }
            }
        }
    }
}

struct FileGridView_Previews: PreviewProvider {
    static var previews: some View {
        FileTreeView(fileInfos: .constant([FileInfo]()), selectionSet: .constant(Set<UUID>()), loadImage: nil)
    }
}
