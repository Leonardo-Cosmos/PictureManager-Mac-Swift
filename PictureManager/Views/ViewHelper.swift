//
//  ViewHelper.swift
//  PictureManager
//
//  Created on 2023/5/3.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

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
    
    static let imagePathExtensions = ["jpg", "jpeg", "png"]
    
    static func isImage(_ url: URL?) -> Bool {
        guard let url = url else {
            return false
        }
        
        return imagePathExtensions.contains(where: { $0 == url.pathExtension })
        
//        let pastedboard = NSPasteboard.general
//        pastedboard.clearContents()
//        pastedboard.writeObjects([NSURL(fileURLWithPath: url!.path)])
//
//        return NSImage.canInit(with: pastedboard)
    }
    
    static func urlToNSItemProvider(_ url: URL) -> NSItemProvider {
        NSItemProvider(item: url.path as NSString, typeIdentifier: UTType.fileListPath.identifier)
    }
    
    static func urlFromNSItemProvider(_ provider: NSItemProvider, completionHandler: @escaping (URL?, Error?) -> Void) {
        
        provider.loadItem(forTypeIdentifier: UTType.fileListPath.identifier) { (item, error) in
            if let error = error {
                completionHandler(nil, error)
            }
            
            do {
                guard let data = item as? Data else {
                    throw LoadUrlError.notDataError
                }
                
                guard let dataDecoded = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSString.self, from: data) else {
                    throw LoadUrlError.decryptDataError
                }
                
                guard let path = dataDecoded as String? else {
                    throw LoadUrlError.notStringError
                }
                
                let fileUrl = URL(fileURLWithPath: path)
                
                completionHandler(fileUrl, nil)
                
            } catch let err as NSError {
                completionHandler(nil, err)
            }
        }
    }
}

