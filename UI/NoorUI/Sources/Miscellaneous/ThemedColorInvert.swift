//
//  ThemedColorInvert.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-12-05.
//

import SwiftUI

private struct ThemedColorInvertModifier: ViewModifier {
    let keepsHues: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.themeStyle) var themeStyle
    @Environment(\.nightBrightness) var nightBrightness

    func body(content: Content) -> some View {
        if colorScheme == .dark || themeStyle == .quiet {
            content
                .colorInvert()
                // Inverting turns each hue to its opposite; turning it back keeps red red on a dark page.
                .hueRotation(.degrees(keepsHues ? 180 : 0))
                .colorMultiply(Color(white: nightBrightness.textLevel))
        } else {
            content
        }
    }
}

extension View {
    public func invertThemedColorIfNeeded(keepingHues: Bool = false) -> some View {
        modifier(ThemedColorInvertModifier(keepsHues: keepingHues))
    }
}
