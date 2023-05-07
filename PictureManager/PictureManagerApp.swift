//
//  PictureManagerApp.swift
//  PictureManager
//
//  Created on 2022/7/26.
//

import SwiftUI

@main
struct PictureManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
//        .windowToolbarStyle(UnifiedWindowToolbarStyle(showsTitle: false))
//        .windowStyle(HiddenTitleBarWindowStyle())
        
        Settings {
            SettingsView()
        }
    }
}
