//
//  SettingsView.swift
//  PictureManager
//
//  Created on 2023/5/7.
//

import SwiftUI

struct SettingsView: View {
    
    static let sidebarViewWidth: Double = 320
    
    static let sidebarViewHeight: Double = 200
    
    static let searchViewWidth: Double = 480
    
    static let searchViewHeight: Double = 300
    
    @State var viewWidth: Double = Self.searchViewWidth
    
    @State var viewHeight: Double = Self.searchViewHeight
    
    @AppStorage("ContentView.dirTreeOnRight")
    private var dirTreeOnRight: Bool = false
    
    @AppStorage("ContentView.fileDetailOnLeft")
    private var fileDetailOnLeft: Bool = false
    
    @AppStorage("FilesView.searchScope")
    private var searchFileScope: SearchFileScope = .currentDirRecursively
    
    @AppStorage("FilesView.searchMatchingTarget")
    private var searchFileMatchingTarget: SearchFileMatchingTarget = .name
    
    @AppStorage("FilesView.searchMatchingMethod")
    private var searchFileMatchingMethod: SearchFileMatchingMethod = .substring
    
    var body: some View {
        TabView {
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
            .tabItem {
                Label("Sidebar", systemImage: "sidebar.leading")
            }
            .onAppear {
                viewWidth = Self.sidebarViewWidth
                viewHeight = Self.sidebarViewHeight
            }
            
            Form {
                List {
                    Text("Search directory scope:")
                    Picker("", selection: $searchFileScope) {
                        Text("Search in Current Directory Only").tag(SearchFileScope.currentDir)
                        Text("Search from Current Directory Recursively").tag(SearchFileScope.currentDirRecursively)
                        Text("Search from Root directory recursively").tag(SearchFileScope.rootDirRecursively)
                    }
                    .padding(.bottom, 8)
                    
                    Text("The property of file used for searching:")
                    Picker("", selection: $searchFileMatchingTarget) {
                        Text("File name").tag(SearchFileMatchingTarget.name)
                        Text("File extension").tag(SearchFileMatchingTarget.nameExtension)
                        Text("File name without extension").tag(SearchFileMatchingTarget.nameWithoutExtension)
                        Text("File path").tag(SearchFileMatchingTarget.path)
                        Text("Parent directory path").tag(SearchFileMatchingTarget.parentDirPath)
                    }
                    .padding(.bottom, 8)
                    
                    Text("The text matching method for searching:")
                    Picker("", selection: $searchFileMatchingMethod) {
                        Text("Substring").tag(SearchFileMatchingMethod.substring)
                        Text("Regular expression").tag(SearchFileMatchingMethod.regex)
                    }
                }
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .onAppear {
                viewWidth = Self.searchViewWidth
                viewHeight = Self.searchViewHeight
            }
            
        }
        .frame(width: viewWidth, height: viewHeight)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
