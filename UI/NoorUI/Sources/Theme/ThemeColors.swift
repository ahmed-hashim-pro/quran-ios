//
//  ThemeColors.swift
//  QuranEngine
//

import SwiftUI
import UIKit

/// Theme colors resolved for SwiftUI.
///
/// Read them with `@Environment(\.themeColors)` instead of wrapping `ThemeStyle`'s `UIColor`s,
/// so they honor `themeColorScheme`. UIKit code keeps using `ThemeStyle`'s `UIColor`s.
public struct ThemeColors: Equatable {
    // MARK: Public

    public var background: Color { resolve(style.backgroundColor, night: night.adjustBackground) }
    public var text: Color { resolve(style.textColor, night: night.adjustText) }
    public var secondaryText: Color { resolve(style.secondaryTextColor, night: night.adjustText) }
    public var secondaryBackground: Color { resolve(style.secondaryBackgroundColor, night: night.adjustBackground) }
    public var pageSeparatorBackground: Color { resolve(style.pageSeparatorBackground) }
    public var pageSeparatorLine: Color { resolve(style.pageSeparatorLine) }

    // MARK: Internal

    let style: ThemeStyle
    let colorScheme: ColorScheme
    var nightBrightness: NightBrightness = .default

    // MARK: Private

    private var night: NightBrightness {
        colorScheme == .dark || style == .quiet ? nightBrightness : .default
    }

    private func resolve(_ color: UIColor) -> Color {
        Color(color.resolvedColor(with: colorScheme.traitCollection))
    }

    private func resolve(_ color: UIColor, night adjust: (UIColor) -> UIColor) -> Color {
        Color(adjust(color.resolvedColor(with: colorScheme.traitCollection)))
    }
}

private struct ThemeColorSchemeOverrideKey: EnvironmentKey {
    static let defaultValue: ColorScheme? = nil
}

extension EnvironmentValues {
    /// Color scheme for theme-colored content. Defaults to the view's color scheme.
    public var themeColorScheme: ColorScheme {
        themeColorSchemeOverride ?? colorScheme
    }

    public var themeColors: ThemeColors {
        ThemeColors(style: themeStyle, colorScheme: themeColorScheme, nightBrightness: nightBrightness)
    }

    var themeColorSchemeOverride: ColorScheme? {
        get { self[ThemeColorSchemeOverrideKey.self] }
        set { self[ThemeColorSchemeOverrideKey.self] = newValue }
    }
}
