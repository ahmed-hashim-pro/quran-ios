//
//  QuranPageInfoVisibility.swift
//  QuranEngine
//

import SwiftUI

private struct ShowsQuranPageInfoKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    /// Whether the surah, juz and page number are drawn around Quran pages.
    public var showsQuranPageInfo: Bool {
        get { self[ShowsQuranPageInfoKey.self] }
        set { self[ShowsQuranPageInfoKey.self] = newValue }
    }
}

private struct QuranPageInfoVisibility: ViewModifier {
    @Environment(\.showsQuranPageInfo) private var showsPageInfo

    func body(content: Content) -> some View {
        // Hidden rather than removed, so turning it off never moves the page.
        content
            .opacity(showsPageInfo ? 1 : 0)
            .accessibilityHidden(!showsPageInfo)
    }
}

extension View {
    func quranPageInfoVisibility() -> some View {
        modifier(QuranPageInfoVisibility())
    }
}
