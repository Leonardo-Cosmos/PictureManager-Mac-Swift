//
//  EnvironmentValuesExtension.swift
//  PictureManager
//
//  Created on 2023/11/23.
//

import SwiftUI

struct SwitchFilesViewDirKey: EnvironmentKey {
    static let defaultValue = SwitchDirAction({ _ in return })
}

extension EnvironmentValues {
    var SwitchFilesViewDir: SwitchDirAction {
        get { self[SwitchFilesViewDirKey.self] }
        set { self[SwitchFilesViewDirKey.self] = newValue }
    }
}
