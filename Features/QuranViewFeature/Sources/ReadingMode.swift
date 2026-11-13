//
//  ReadingMode.swift
//  QuranEngine
//

import Localization
import NoorUI

/// quran_android's Day, Sepia and Night, as shortcuts to the reader's own theme settings.
enum ReadingMode: CaseIterable {
    case day
    case sepia
    case night

    // MARK: Lifecycle

    /// What the reader shows: dark is night whatever the style, as night brightness treats it.
    init(themeStyle: ThemeStyle, isDark: Bool) {
        if isDark || themeStyle == .quiet {
            self = .night
        } else if themeStyle == Self.sepiaStyle {
            self = .sepia
        } else {
            self = .day
        }
    }

    // MARK: Internal

    static let dayStyle = ThemeStyle.original
    static let sepiaStyle = ThemeStyle.paper

    var title: String {
        switch self {
        case .day: lAndroid("reading_mode_day")
        case .sepia: lAndroid("reading_mode_sepia")
        case .night: lAndroid("reading_mode_night")
        }
    }

    /// Night keeps the style, so the page is that style's dark variant.
    @MainActor
    func apply(to themeService: ThemeService) {
        switch self {
        case .day:
            themeService.themeStyle = Self.dayStyle
            themeService.appearanceMode = .light
        case .sepia:
            themeService.themeStyle = Self.sepiaStyle
            themeService.appearanceMode = .light
        case .night:
            themeService.appearanceMode = .dark
        }
    }
}
