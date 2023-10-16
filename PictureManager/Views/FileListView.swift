//
//  FileListView.swift
//  PictureManager
//
//  Created on 2021/10/17.
//

import SwiftUI
import os
import UniformTypeIdentifiers

struct FileListView: View {
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
    
    var rootDirUrl: URL?
    
    @Binding var selectedUrls: [URL]

    @AppStorage("FileListView.sortBy")
    private var sortBy: SortBy = .name

    @AppStorage("FileListView.viewStyle")
    private var viewStyle: ViewStyle = .list

    @State private var fileInfos = [FileInfo]()

    @State private var fileIdDict = [UUID: FileInfo]()

    @State private var multiSelection = Set<UUID>()

    @State private var selectedFileUrl: URL?
    
    var body: some View {
        HStack {
            List(fileInfos, selection: $multiSelection) { file in
                HStack {
                    ImageView(file: file)
                    Text(file.name)
                }
                .onAppear {
                    if !file.loaded {
                        loadImage(file: file)
                        file.loaded = true
                    }
                }
            }
            .onCutCommand() { () in
                let providers = selectedUrls.map(ViewHelper.urlToNSItemProvider)
                FileListView.logger.debug("Cut file count: \(providers.count)")
                return providers
            }
            .onCopyCommand() {
                let providers = selectedUrls.map(ViewHelper.urlToNSItemProvider)
                FileListView.logger.debug("Copied file count: \(providers.count)")
                return providers
            }
            .onPasteCommand(of: [UTType.fileListPath.identifier], validator: { providers in
                guard rootDirUrl != nil else {
                    return nil
                }
                return providers
            }, perform: { (providers: [NSItemProvider]) in
                for provider in providers {
                    ViewHelper.urlFromNSItemProvider(provider) { (fileUrl, error) in
                        if let error = error {
                            FileListView.logger.error("Cannot load pasted path, \(error.localizedDescription)")
                        } else  if let fileUrl = fileUrl {
                            do {
                                try FileSystemManager.default.copyFile(fileUrl.lastPathComponent, from: fileUrl.deletingLastPathComponent().path, to: rootDirUrl!.path)
                                fileInfos.append(FileInfo(url: fileUrl))
                            } catch let error {
                                FileListView.logger.error("Cannot paste file, \(error.localizedDescription)")
                            }
                        }
                    }
                }
            })
            .onChange(of: multiSelection, perform: updateMultiSelection)
        }
        .navigationTitle(rootDirUrl?.lastPathComponent ?? "")
        .onChange(of: rootDirUrl, perform: loadFiles)
    }

    private func loadFiles(dirUrl: URL?) {
        fileInfos.removeAll()
        fileIdDict.removeAll()
        multiSelection.removeAll()
        selectedFileUrl = nil

        guard let dirUrl = dirUrl else {
            return
        }

        Self.logger.debug("List files of directory \(dirUrl.path)")

        var filePaths: [String]
        do {
            filePaths = try FileSystemManager.default.filesOfDirectory(atPath: dirUrl.path)
        } catch let error as NSError {
            Self.logger.error("Cannot list files. \(error)")
            return
        }

        Self.logger.debug("Number of files \(filePaths.count)")

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
    
    private func updateMultiSelection(ids: Set<UUID>) -> Void {
        let selectedFileSet = ids
            .map { fileIdDict[$0] }
            .filter { $0 != nil }
        selectedUrls = selectedFileSet.map({ $0!.url })
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

    private func loadImage(file: FileInfo) {
        let fileUrl = file.url

        if !ViewHelper.isImage(fileUrl) {
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            guard let nsImage = NSImage(contentsOf: fileUrl) else {
                return
            }

            DispatchQueue.main.async {
                file.image = Image(nsImage: nsImage)
            }
        }
    }

    private func switchToIconView() {

    }

    private func switchToListView() {

    }
}

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

struct ImageView: View {
    
    let imageLength: Double = 64
    
    @ObservedObject var file: FileInfo
    
    var body: some View {
        if let image = file.image {
            image
                .resizable()
                .aspectRatio(contentMode: ContentMode.fit)
                .frame(width: imageLength, height: imageLength)
                .cornerRadius(5)
        }
    }
}

struct FileListView_Previews: PreviewProvider {
    static var previews: some View {
        FileListView(rootDirUrl: URL(fileURLWithPath: "."), selectedUrls: .constant([URL]()))
    }
}
