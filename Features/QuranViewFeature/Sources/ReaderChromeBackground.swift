//
//  ReaderChromeBackground.swift
//  QuranEngine
//

import SwiftUI

extension View {
    /// The capsule behind the reader's floating controls, such as the translation strip and the reading modes.
    @ViewBuilder
    func readerChromeBackground() -> some View {
        if #available(iOS 26.1, *) {
            glassEffect(in: .capsule)
        } else {
            background(.thinMaterial, in: Capsule())
        }
    }
}
