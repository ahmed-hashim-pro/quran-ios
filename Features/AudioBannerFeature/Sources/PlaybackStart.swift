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
        let offersLastRange = lastRange.map { $0.start.page <= page && page <= $0.end.page } ?? false
        let opensWithItsOnlySura = startingSuras.count == 1 && startingSuras[0] == page.startSura
        guard offersLastRange || !(startingSuras.isEmpty || opensWithItsOnlySura) else {
            return []
        }

        var choices: [PlaybackStart] = []
        if offersLastRange, let lastRange {
            choices.append(.lastRange(lastRange))
        }
        // A surah opening the page already starts it.
        if startingSuras.first != page.startSura {
            choices.append(.page(page))
        }
        choices += startingSuras.map(PlaybackStart.sura)
        return choices
    }
}
