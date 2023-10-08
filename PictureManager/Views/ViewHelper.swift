//
//  ViewHelper.swift
//  PictureManager
//
//  Created on 2023/5/3.
//

import Foundation
import SwiftUI

struct ViewHelper {
    
    static func mainScreenWidth(defaultValue: Double) -> Double {
        if let mainScreenWidth = NSScreen.main?.frame.size.width {
            return Double(mainScreenWidth)
        } else {
            return defaultValue
        }
    }
    
    static func openDirectoryPanel() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK {
            return panel.url
        } else {
            return nil
        }
    }
    
    static func isImage(_ url: URL?) -> Bool {
        guard let url = url else {
            return false
        }
        
        return url.pathExtension == ".jpg"
        
//        let pastedboard = NSPasteboard.general
//        pastedboard.clearContents()
//        pastedboard.writeObjects([NSURL(fileURLWithPath: url!.path)])
//
//        return NSImage.canInit(with: pastedboard)
    }
}
