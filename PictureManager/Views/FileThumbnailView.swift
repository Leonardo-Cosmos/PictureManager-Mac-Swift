//
//  FileThumbnailView.swift
//  PictureManager
//
//  Created on 2023/10/19.
//

import SwiftUI

struct FileThumbnailView: View {
    
    let imageLength: Double = 64
    
    @ObservedObject var thumbnail: ThumbnailCache
    
    let isDirectory: Bool
    
    var body: some View {
        if let image = thumbnail.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: ContentMode.fit)
                    .frame(width: imageLength, height: imageLength)
                    .cornerRadius(5)
        } else {
            if isDirectory {
                Image(systemName: "folder")
                    .resizable()
                    .aspectRatio(contentMode: ContentMode.fit)
                    .frame(width: imageLength, height: imageLength)
                    .cornerRadius(5)
            } else {
                Image(systemName: "doc")
                    .resizable()
                    .aspectRatio(contentMode: ContentMode.fit)
                    .frame(width: imageLength, height: imageLength)
                    .cornerRadius(5)
            }
        }
    }
}

struct FileThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
//        FileThumbnailView(file: DirectoryInfo(url: URL(dirPathString: ".")))
        FileThumbnailView(thumbnail: ThumbnailCache(), isDirectory: false)
    }
}
