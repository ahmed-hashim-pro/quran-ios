//
//  ReaderBookmarkPage.swift
//  QuranEngine
//

import QuranKit

extension [Page] {
    /// quran_android's bookmark button acts on its current page, which in two-page mode is the
    /// second, even page of the pair.
    var bookmarkPage: Page? {
        self.max()
    }
}
