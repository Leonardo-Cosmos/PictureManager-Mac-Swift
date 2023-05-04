//
//  ViewHelper.swift
//  PictureManager
//
//  Created on 2023/5/3.
//

import Foundation
import SwiftUI

struct ViewHelper {
    
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
        if url == nil {
            return false
        }
        
        let pastedboard = NSPasteboard.general
        pastedboard.clearContents()
        pastedboard.writeObjects([NSURL(fileURLWithPath: url!.path)])
        
        return NSImage.canInit(with: pastedboard)
    }
}
