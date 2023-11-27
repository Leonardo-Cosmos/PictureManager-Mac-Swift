//
//  PathBar.swift
//  PictureManager
//
//  Created on 2023/11/23.
//

import SwiftUI

struct PathBar: View {
    
    @Binding var directory: DirectoryInfo?
    
    var body: some View {
        HStack {
            
        }
    }
}

struct PathBar_Previews: PreviewProvider {
    static var previews: some View {
        PathBar(directory: .constant(DirectoryInfo(path: ".")))
    }
}
