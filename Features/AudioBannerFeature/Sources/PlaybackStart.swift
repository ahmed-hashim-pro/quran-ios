//
//  PlaybackStart.swift
//

import QuranAudioKit
import QuranKit

/// Where quran_android's Play offers to start when a page holds more than one place to begin.
enum PlaybackStart: Equatable, Sendable {
    case lastRange(LastPlaybackRange)
    case page(Page)
    case sura(Sura)

    // MARK: Internal

    /// Empty when Play starts the page without asking: no remembered range covers it, and it either
    /// starts no surah or opens with the only surah starting on it.
    static func choices(on page: Page, lastRange: LastPlaybackRange?) -> [PlaybackStart] {
        let startingSuras = page.suras.filter { $0.page == page }
        let coveringRange = rememberedRange(covering: page, lastRange: lastRange)
        let opensWithItsOnlySura = startingSuras.count == 1 && startingSuras[0] == page.startSura
        guard coveringRange != nil || !(startingSuras.isEmpty || opensWithItsOnlySura) else {
            return []
        }

        var choices: [PlaybackStart] = []
        if let coveringRange {
            choices.append(.lastRange(coveringRange))
        }
        // A surah opening the page already starts it.
        if startingSuras.first != page.startSura {
            choices.append(.page(page))
        }
        choices += startingSuras.map(PlaybackStart.sura)
        return choices
    }

    /// `lastRange` when its pages take in `page`: quran_android then offers it, and its audio panel shows it.
    static func rememberedRange(covering page: Page, lastRange: LastPlaybackRange?) -> LastPlaybackRange? {
        guard let lastRange, lastRange.start.page <= page, page <= lastRange.end.page else {
            return nil
        }
        return lastRange
    }
}
