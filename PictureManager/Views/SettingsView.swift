//
//  SettingsView.swift
//  PictureManager
//
//  Created on 2023/5/7.
//

import SwiftUI

struct SettingsView: View {
    
    @AppStorage("ContentView.dirTreeOnRight")
    private var dirTreeOnRight: Bool = false
    
    @AppStorage("ContentView.fileDetailOnLeft")
    private var fileDetailOnLeft: Bool = false
    
    var body: some View {
        Form {
            Toggle(isOn: $dirTreeOnRight) {
                Text("Directory tree on right side")
            }
            .toggleStyle(.checkbox)
            .padding([.leading, .trailing, .top])
            
            Toggle(isOn: $fileDetailOnLeft) {
                Text("File detail on left side")
            }
            .toggleStyle(.checkbox)
            .padding([.leading, .trailing, .top, .bottom])
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
