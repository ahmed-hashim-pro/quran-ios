//
//  ThemedColorInvert.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-12-05.
//

import SwiftUI

private struct ThemedColorInvertModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.themeStyle) var themeStyle
    @Environment(\.nightBrightness) var nightBrightness

    func body(content: Content) -> some View {
        if colorScheme == .dark || themeStyle == .quiet {
            content
                .colorInvert()
                .colorMultiply(Color(white: nightBrightness.textLevel))
        } else {
            content
        }
    }
}

extension View {
    public func invertThemedColorIfNeeded() -> some View {
        modifier(ThemedColorInvertModifier())
    }
}
