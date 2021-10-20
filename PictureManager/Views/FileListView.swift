//
//  FileListView.swift
//  PictureManager
//
//  Created on 2021/10/17.
//

import SwiftUI

struct FileListView: View {
    
    let dirPath: URL
    
    @State var files = [FileInfo]()
    
    var body: some View {
        List(files) { file in
            Text(file.name)
        }.onAppear(perform: {
            let files = FileSystemManager.Default.filesOfDirectory(atPath: dirPath.path)
            print("List files of directory \(dirPath.path), number of files \(files.count)")
            self.files = files.map { file in FileInfo(url: URL(fileURLWithPath: file)) }
        })
    }
}

struct FileListView_Previews: PreviewProvider {
    static var previews: some View {
        FileListView(dirPath: URL(fileURLWithPath: "."))
    }
}
