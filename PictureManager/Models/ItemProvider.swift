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

enum LoadUrlError: Error {
    case notDataError
    case decryptDataError
    case notStringError
    case invalidUrl(string: String)
}

extension LoadUrlError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notDataError:
            return NSLocalizedString("The item of NSItemProvider is not type of Data", comment: "notDataError")
        case .decryptDataError:
            return NSLocalizedString("Cannot decrypt the item of NSItemProvider", comment: "decryptDataError")
        case .notStringError:
            return NSLocalizedString("The item of NSItemProvider is not type of String", comment: "notDataError")
        case .invalidUrl(string: let str):
            return NSLocalizedString("The string \"\(str)\" is not a valid URL", comment: "invalidUrl")
        }
    }
}
