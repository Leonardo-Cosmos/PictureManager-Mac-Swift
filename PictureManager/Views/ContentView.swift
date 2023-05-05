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

    @AppStorage("ContentView.dirTreeWidth")
    private var dirTreeWidth: Double = 200
    
    private let dirTreeMinWidth: Double = 100
    
    private let fileListMinWidth: Double = 200
    
    @State private var isDragging = false
    
    @State private var selectedDirectoryUrl: URL?
    
    var body: some View {
        HStack(spacing: 0) {
            
            DirectoryTreeView(selectedUrl: $selectedDirectoryUrl)
                .frame(minWidth: dirTreeMinWidth, maxWidth: .infinity, maxHeight: .infinity)
                .frame(width: dirTreeWidth)
                .onChange(of: selectedDirectoryUrl) { dirUrl in
                    guard let url = dirUrl else {
                        return
                    }
                    Self.logger.debug("Selected \(url.lastPathComponent)")
                }

            Divider()
                .frame(width: 3)
                .overlay(.ultraThickMaterial)
                .background(Color.gray.opacity(isDragging ? 0.5 : 0))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            updateDirTreeViewWidth(value.translation.width)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
                .onHover { inside in
                    if inside {
                        NSCursor.resizeLeftRight.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
            
            FileListView(fileDirUrl: selectedDirectoryUrl)
                .frame(minWidth: fileListMinWidth, maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func updateDirTreeViewWidth(_ width: CGFloat) {
        dirTreeWidth += width
        if dirTreeWidth < dirTreeMinWidth {
            dirTreeWidth = dirTreeMinWidth
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
