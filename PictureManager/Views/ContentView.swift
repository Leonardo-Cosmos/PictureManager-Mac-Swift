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
    
    var body: some View {
        NavigationView {
            DirectoryView()
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
