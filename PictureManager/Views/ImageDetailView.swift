//
//  ImageDetailView.swift
//  PictureManager
//
//  Created on 2022/8/13.
//

import SwiftUI

struct ImageDetailView: View {
    var fileUrl: URL?
    
    var body: some View {
        if ViewHelper.isImage(fileUrl) {
            Image(nsImage: NSImage(byReferencing: fileUrl!))
                .resizable()
                .aspectRatio(contentMode: ContentMode.fit)
                .frame(minWidth: 256, maxWidth: .infinity,
                       minHeight: 256, maxHeight: .infinity)
        }
    }
    
    private func loadFileAttributes() {
        
    }
}

struct ImageDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ImageDetailView(fileUrl: URL(fileURLWithPath: "./Resources/Xcode.png"))
    }
}
