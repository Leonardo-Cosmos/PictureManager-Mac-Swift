//
//  ContentView.swift
//  PictureManager
//
//  Created on 2021/3/21.
//

import SwiftUI



struct ContentView: View {
    
    @State var files = [
        FileInfo(name: "a"),
        FileInfo(name: "b"),
        FileInfo(name: "c"),
    ]
    
    let tree = DirectoryInfo(content: "Root",
                        children: [.init(content: "Level1",
                                         children: [.init(content: "Level2")])])
    
    var body: some View {
        NavigationView {
            VStack{
                List {
                    OutlineGroup(tree, id: \.id, children: \.children) { node in
                        Text(node.content)
                    }
                }.navigationTitle("Folders")
            }
            List(files, id: \.id) { file in
                Text(file.name)
            }
        }.navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
