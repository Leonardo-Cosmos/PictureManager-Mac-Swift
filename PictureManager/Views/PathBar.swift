//
//  PathBar.swift
//  PictureManager
//
//  Created on 2023/11/23.
//

import SwiftUI

struct PathBar: View {
    
    let imageLength: Double = 16
    
    @Binding var directory: DirectoryInfo?
    
    @Environment(\.SwitchFilesViewDir) private var switchDir: SwitchDirAction
    
    var body: some View {
        ZStack {
            Color(nsColor: NSColor.controlBackgroundColor)
                .ignoresSafeArea()
            
            HStack {
                if let currentDirectory = directory {
                    if let directories = directory?.ancients {
                        ForEach(directories) { dir in
                            Button(action: { switchDir(dir: dir) }) {
                                if let image = dir.thumbnail.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: ContentMode.fit)
                                        .frame(width: imageLength, height: imageLength)
                                        .cornerRadius(5)
                                }
                                Text(dir.name)
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                    
                    HStack {
                        Button(action: { switchDir(dir: currentDirectory) }) {
                            if let image = currentDirectory.thumbnail.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: ContentMode.fit)
                                    .frame(width: imageLength, height: imageLength)
                                    .cornerRadius(5)
                            }
                            Text(currentDirectory.name)
                        }
                    }
                } else {
                    Text("")
                }
            }
            .buttonStyle(.borderless)
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 6, trailing: 12))
        }
        .frame(height: 28)
    }
}

struct PathBar_Previews: PreviewProvider {
    static var previews: some View {
        PathBar(directory: .constant(DirectoryInfo(path: ".")))
    }
}
