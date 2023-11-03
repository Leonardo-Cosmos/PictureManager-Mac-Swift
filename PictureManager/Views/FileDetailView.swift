//
//  FileDetailView.swift
//  PictureManager
//
//  Created on 2022/8/16.
//

import SwiftUI
import os

struct FileDetailView: View {
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
    
    let fileUrl: URL?
    
    let units = ["bytes", "KB", "MB", "GB"]
    
    @State private var size = ""
    
    var body: some View {
        VStack {
            ImageDetailView(fileUrl: fileUrl)
            Text(fileUrl?.lastPathComponent ?? "")
            Text(size)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onChange(of: fileUrl, perform: loadFileAttributes)
    }
    
    private func loadFileAttributes(url: URL?) {
        if url != nil {
            Self.logger.debug("Load file attribute: \(url!.purePath)")
            if let fileAttributes = try? FileSystemManager.default.attributes(url!.purePath) {
//                size = formatFileSize(FileSystemManager.size(attributes: fileAttributes))
            }
        } else {
            size = ""
        }
    }
    
    private func formatFileSize(_ size: UInt64) -> String {
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedSize = formatter.string(from: NSNumber(value: size)) ?? ""
        
        var number = Float(size)
        
        for unit in units {
            if number < 1000 || unit == units.last {
                let formattedNumber = String(format: "%.1f", arguments: [number])
                return "\(formattedNumber) \(unit) (\(formattedSize) bytes)"
            } else {
                number = number / 1000
            }
        }
        
        return "\(formattedSize) bytes"
    }
}

struct FileDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FileDetailView(fileUrl: nil)
    }
}
