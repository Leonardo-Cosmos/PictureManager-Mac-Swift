//
//  ContentView.swift
//  PictureManager
//
//  Created on 2021/3/21.
//

import SwiftUI

struct ContentView: View {

    @State var files = [
    ]

    var body: some View {
        NavigationView {
            DirectoryTreeView()
        }.navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
