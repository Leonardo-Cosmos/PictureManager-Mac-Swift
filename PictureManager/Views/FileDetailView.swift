//
//  FileDetailView.swift
//  PictureManager
//
//  Created on 2022/8/16.
//

import SwiftUI

struct FileDetailView: View {
    var fileUrl: URL
    
    let units = ["bytes", "KB", "MB", "GB"]
    
    @State private var fileSize = ""
    
    @State private var fileType = ""
    
    var body: some View {
        VStack {
            if fileUrl.pathExtension == "jpg" {
                ImageDetailView(fileUrl: fileUrl)
            }
            Text(fileUrl.lastPathComponent)
            Text(fileSize)
                .font(.caption)
                .foregroundColor(.secondary)
        }.onAppear(perform: loadFileAttributes)
    }
    
    private func loadFileAttributes() {
        if let fileAttributes = try? FileSystemManager.Default.attributes(fileUrl.path) {
            
            fileSize = formatFileSize(FileSystemManager.size(attributes: fileAttributes))
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
        FileDetailView(fileUrl: URL(fileURLWithPath: "./Resources/Xcode.png"))
    }
}
