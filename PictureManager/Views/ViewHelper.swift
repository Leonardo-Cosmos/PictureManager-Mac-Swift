//
//  ViewHelper.swift
//  PictureManager
//
//  Created on 2023/5/3.
//

import Foundation
import SwiftUI
import System
import QuickLookThumbnailing
import UniformTypeIdentifiers
import os

struct ViewHelper {
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
    
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
    
    static func isImage(path: String) -> Bool {
        let filePath = FilePath(path)
        return imagePathExtensions.contains(where: { $0 == filePath.extension })
        
//        let pastedboard = NSPasteboard.general
//        pastedboard.clearContents()
//        pastedboard.writeObjects([NSURL(fileURLWithPath: url!.purePath)])
//
//        return NSImage.canInit(with: pastedboard)
    }
    
    static func urlToNSItemProvider(_ url: URL) -> NSItemProvider {
        NSItemProvider(item: url.purePath as NSString, typeIdentifier: UTType.fileListPath.identifier)
    }
    
    static func pathFromNSItemProvider(_ provider: NSItemProvider, completionHandler: @escaping (String?, Error?) -> Void) {
        
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
                
                completionHandler(path, nil)
                
            } catch let err as NSError {
                completionHandler(nil, err)
            }
        }
    }
    
    static func loadThumbnail(file: FileInfo) {
        let fileUrl = file.url

        DispatchQueue.global(qos: .userInitiated).async {
            
            generateThumbnailRepresentations(url: fileUrl) { (nsImage) in
                
                DispatchQueue.main.async {
                    file.thumbnail.image = Image(nsImage: nsImage)
                }
            }
        }
    }
    
    static func generateThumbnailRepresentations(url: URL, update updateHandler: @escaping (NSImage) -> Void) {
        
        // Set up the parameters of the request.
        let size: CGSize = CGSize(width: 60, height: 90)
        let scale = CGFloat(integerLiteral: 1)
        
        // Create the thumbnail request.
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: scale, representationTypes: .all)
        
        // Retrieve the singleton instance of the thumbnail generator and generate the thumbnails.
        let generator = QLThumbnailGenerator.shared
        generator.generateRepresentations(for: request) { (thumbnail, type, error) in
            if let error = error {
                Self.logger.error("Cannot generate thumbnail, path: \(url.purePath), type: \(type.rawValue), \(error)")
                return
            }
            
            guard let nsImage = thumbnail?.nsImage else {
                Self.logger.error("No thumbnail generated, path: \(url.purePath), type: \(type.rawValue)")
                return
            }
            
            Self.logger.debug("Generated thumbnail, path: \(url.purePath) type: \(type.rawValue)")
            
            updateHandler(nsImage)
        }
    }
    
    static func loadUrlResourceValues(files: [FileInfo], complete: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            
            var fileResourceTuples: [(file: FileInfo, resourceValues: URLResourceValues)] = []
            for file in files {
                do {
                    let resourceValues = try file.url.resourceValues(forKeys: file.resourceKeySet)
                    fileResourceTuples.append((file, resourceValues))
                } catch let err {
                    Self.logger.error("Cannot retrieve URL resource values, path: \(file.url.purePath), \(err)")
                }
            }
            
            DispatchQueue.main.async {
                for fileResourceTuple in fileResourceTuples {
                    fileResourceTuple.file.populateResourceValues(fileResourceTuple.resourceValues)
                }
                
                if let complete = complete {
                    complete()
                }
            }
        }
    }
    
}

