//
//  ThumbnailInfo.swift
//  PictureManager
//
//  Created on 2023/10/20.
//

import Foundation
import SwiftUI

class ThumbnailCache: ObservableObject {
    
    var requested: Bool = false
    
    @Published var image: Image?
    
}
