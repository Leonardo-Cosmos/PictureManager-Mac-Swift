//
//  ImageDetailView.swift
//  PictureManager
//
//  Created on 2022/8/13.
//

import SwiftUI

struct ImageDetailView: View {
    
    let imageMinWidth: Double = 32
    
    let imageMinHeight: Double = 32
    
    var fileUrl: URL?
    
    var body: some View {
        if let fileUrl = fileUrl {
            if ViewHelper.isImage(path: fileUrl.purePath) {
                Image(nsImage: NSImage(byReferencing: fileUrl))
                    .resizable()
                    .aspectRatio(contentMode: ContentMode.fit)
                    .frame(minWidth: imageMinWidth, maxWidth: .infinity,
                           minHeight: imageMinHeight, maxHeight: .infinity)
            }
        }
    }
}

struct ImageDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ImageDetailView(fileUrl: URL(fileNotDirPathString: "./Resources/Xcode.png"))
    }
}
