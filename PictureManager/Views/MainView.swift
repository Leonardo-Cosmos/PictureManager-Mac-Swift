//
//  MainView.swift
//  PictureManager
//
//  Created on 2021/3/28.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        HSplitView /*@START_MENU_TOKEN@*/{
            Section {
                /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Section Content@*/Text("Section Content")/*@END_MENU_TOKEN@*/
            }
            Text("Leading")
            Text("Trailing")
        }.frame(width: 800, height: 600, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)/*@END_MENU_TOKEN@*/
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
