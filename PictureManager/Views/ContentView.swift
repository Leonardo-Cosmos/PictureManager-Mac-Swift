//
//  ContentView.swift
//  PictureManager
//
//  Created on 2021/3/21.
//

import SwiftUI
import os

struct ContentView: View {
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
    
    @AppStorage("ContentView.dirTreeOnRight")
    private var dirTreeOnRight: Bool = false
    
    @AppStorage("ContentView.dirTreeWidth")
    private var dirTreeWidth: Double = 200
    
    private let dirTreeMinWidth: Double = 50
    
    private let dirTreeMaxWidth: Double = ViewHelper.mainScreenWidth(defaultValue: 1600)
    
    @State private var isDraggingDirTree = false
    
    private let fileListMinWidth: Double = 100
    
    @AppStorage("ContentView.fileDetailOnLeft")
    private var fileDetailOnLeft: Bool = false
    
    @AppStorage("FileListView.fileDetailWidth")
    private var fileDetailWidth: Double = 100
    
    private let fileDetailMinWidth: Double = 50
    
    private let fileDetailMaxWidth: Double = ViewHelper.mainScreenWidth(defaultValue: 1600)
    
    @State private var isDraggingFileDetail = false
    
    @State private var selectedDirectoryUrl: URL?
    
    @State private var selectedFileUrls: [URL] = [URL]()
    
    @State private var selectedFileUrl: URL?
    
    var body: some View {
        HStack(spacing: 0) {
            if (!dirTreeOnRight) {
                createDirTreeView()
                createDirTreeDivider()
            }
            
            if (fileDetailOnLeft) {
                createFileDetailView()
                createFileDetailDivider()
            }
            
            createFileListView()
            
            if (!fileDetailOnLeft) {
                createFileDetailDivider()
                createFileDetailView()
            }
            
            if (dirTreeOnRight) {
                createDirTreeDivider()
                createDirTreeView()
            }
        }
//        .toolbar {
//            ToolbarItemGroup(placement: .navigation) {
//                Button(action: {}, label: {
//                    Image(systemName: "sidebar.left")
//                })
//                Spacer()
//                Button(action: {}, label: {
//                    Image(systemName: "play.fill")
//                })
//                Button(action: {}, label: {
//                    Image(systemName: "stop.fill")
//                })
//            }
//            ToolbarItem(placement: .confirmationAction) {
//                Button(action: {}, label: {
//                    Image(systemName: "sidebar.right")
//                })
//            }
//        }
    }
    
    @ViewBuilder private func createDirTreeView() -> some View {
        DirectoryTreeView(selectedUrl: $selectedDirectoryUrl)
            .frame(minWidth: dirTreeMinWidth, maxWidth: .infinity, maxHeight: .infinity)
            .frame(width: dirTreeWidth)
            .onChange(of: selectedDirectoryUrl) { dirUrl in
                guard let url = dirUrl else {
                    return
                }
                Self.logger.debug("Selected \(url.lastPathComponent)")
            }
            .listStyle(.sidebar)
    }
    
    @ViewBuilder private func createDirTreeDivider() -> some View {
        Divider()
            .frame(width: 3)
            .overlay(.ultraThickMaterial)
            .background(Color.gray.opacity(isDraggingDirTree ? 0.5 : 0))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDraggingDirTree = true
                        updateDirTreeViewWidth(value.translation.width)
                    }
                    .onEnded { _ in
                        isDraggingDirTree = false
                    }
            )
            .onHover { inside in
                if inside {
                    NSCursor.resizeLeftRight.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
    }
    
    private func updateDirTreeViewWidth(_ width: CGFloat) {
        if dirTreeOnRight {
            dirTreeWidth -= width
        } else {
            dirTreeWidth += width
        }
        
        if dirTreeWidth < dirTreeMinWidth {
            dirTreeWidth = dirTreeMinWidth
        } else if dirTreeWidth > dirTreeMaxWidth {
            Self.logger.warning("Directory tree size is over max width (\(dirTreeMaxWidth)")
            dirTreeWidth = dirTreeMaxWidth
        }
    }
    
    @ViewBuilder private func createFileListView() -> some View {
        FileListView(rootDirUrl: selectedDirectoryUrl, selectedUrls: $selectedFileUrls)
            .frame(minWidth: fileListMinWidth, maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: selectedFileUrls, perform: { selections in
                selectedFileUrl = selections.first
            })
    }
    
    @ViewBuilder private func createFileDetailView() -> some View {
        FileDetailView(fileUrl: selectedFileUrl)
            .frame(minWidth: fileDetailMinWidth, maxWidth: .infinity, maxHeight: .infinity)
            .frame(width: fileDetailWidth)
    }
    
    @ViewBuilder private func createFileDetailDivider() -> some View {
        Divider()
            .frame(width: 3)
            .overlay(.ultraThickMaterial)
            .background(Color.gray.opacity(isDraggingFileDetail ? 0.5 : 0))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDraggingFileDetail = true
                        updateFileDetailViewWidth(value.translation.width)
                    }
                    .onEnded { _ in
                        isDraggingFileDetail = false
                    }
            )
            .onHover { inside in
                if inside {
                    NSCursor.resizeLeftRight.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
    }
    
    private func updateFileDetailViewWidth(_ width: CGFloat) {
        if fileDetailOnLeft {
            fileDetailWidth += width
        } else {
            fileDetailWidth -= width
        }
        
        if fileDetailWidth < fileDetailMinWidth {
            fileDetailWidth = fileDetailMinWidth
        } else if fileDetailWidth > fileDetailMaxWidth {
            fileDetailWidth = fileDetailMaxWidth
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//
//class MainWindowController: NSWindowController, NSWindowDelegate {
//    private static let windowX = "windowX"
//    private static let windowY = "windowY"
//    private static let windowWidth = "windowWidth"
//    private static let windowHeight = "windowHeight"
//    
//    override func windowDidLoad() {
//        super.windowDidLoad()
//        if let window = window {
//            let x = UserDefaults.standard.double(forKey: MainWindowController.windowX)
//            let y = UserDefaults.standard.double(forKey: MainWindowController.windowY)
//            let width = UserDefaults.standard.double(forKey: MainWindowController.windowWidth)
//            let height = UserDefaults.standard.double(forKey: MainWindowController.windowHeight)
//            window.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
//        }
//    }
//    
//    func windowShouldClose(_ sender: NSWindow) -> Bool {
//        let frame = sender.frame
//        UserDefaults.standard.set(frame.origin.x, forKey: MainWindowController.windowX)
//        UserDefaults.standard.set(frame.origin.y, forKey: MainWindowController.windowY)
//        UserDefaults.standard.set(frame.size.width, forKey: MainWindowController.windowWidth)
//        UserDefaults.standard.set(frame.size.height, forKey: MainWindowController.windowHeight)
//        return true
//    }
//}
