//
//  ContentView.swift
//  PictureManager
//
//  Created on 2021/3/21.
//

import SwiftUI

struct ContentView: View {

    @State var files = [
    ]

    var body: some View {
        NavigationView {
            DirectoryTreeView()
        }
        .navigationViewStyle(ColumnNavigationViewStyle.columns)
        .toolbar {
            ToolbarItem {
                Button(action: {}) {
                    Label("List", systemImage: "list.bullet")
                }
            }
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
