//
//  ImageDetailView.swift
//  PictureManager
//
//  Created on 2022/8/13.
//

import SwiftUI

struct ImageDetailView: View {
    var fileUrl: URL
    
    var body: some View {
        Image(nsImage: NSImage(byReferencing: fileUrl))
            .resizable()
            .aspectRatio(contentMode: ContentMode.fit)
            .frame(width: 256, height: 256)
    }
    
    private func loadFileAttributes() {
        
    }
}

struct ImageDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ImageDetailView(fileUrl: URL(fileURLWithPath: "./Resources/Xcode.png"))
    }
}
