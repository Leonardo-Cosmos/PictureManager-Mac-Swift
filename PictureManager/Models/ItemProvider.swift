//
//  UTTypeExtension.swift
//  PictureManager
//
//  Created on 10/7/23.
//

import UniformTypeIdentifiers

extension UTType {
    static var fileListPath: UTType {
        UTType(exportedAs: "com.cosmos.path")
    }
}
