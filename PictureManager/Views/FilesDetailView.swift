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
    
    @State var oldDir: DirectoryInfo? = nil
    
    var body: some View {
        ScrollViewReader { proxy in
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
            .onChange(of: dir) { _ in
                if oldDir != nil && dir != nil {
                    scrollWhenSwitch(proxy, oldDir: oldDir!, newDir: dir!)
                }
                oldDir = dir
            }
        }
    }
    
    /**
     If view switches to a new directory which is an ancient of the old directory, scroll to the child directory which is or contains the old directory.
     */
    private func scrollWhenSwitch(_ proxy: ScrollViewProxy, oldDir: DirectoryInfo, newDir: DirectoryInfo) {
        if let newDir = dir {
            if oldDir.ancients.contains(newDir) {
                var child: DirectoryInfo? = oldDir
                while (child != nil) {
                    if child!.parent == newDir {

                        DispatchQueue.main.async {
                            /*
                             Xcode mentions: "Publishing changes from within view updates is not allowed, this will cause undefined behavior."
                             */
                            proxy.scrollTo(child!.id)
                            // Need to scroll twice, otherwise the scroll is not done.
                            proxy.scrollTo(child!.id)
                        }
                        break
                    }
                    child = child!.parent
                }
            }
        }
    }
}

struct FilesDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FilesDetailView(dir: .constant(DirectoryInfo(path: ".")), selectionSet: .constant(Set<UUID>()), sortOrder: .constant([SortDescriptor<FileInfo>(\.name)]), refreshState: .constant(false))
    }
}
