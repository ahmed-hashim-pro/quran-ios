//
//  LastPlaybackRange.swift
//

import Preferences
import QuranAudio
import QuranKit

/// The range last played from the audio options, with its repeats: what quran_android remembers as the drill.
public struct LastPlaybackRange: Equatable, Sendable {
    // MARK: Lifecycle

    public init(start: AyahNumber, end: AyahNumber, verseRuns: Runs, listRuns: Runs) {
        self.start = start
        self.end = end
        self.verseRuns = verseRuns
        self.listRuns = listRuns
    }

    // MARK: Public

    public let start: AyahNumber
    public let end: AyahNumber
    public let verseRuns: Runs
    public let listRuns: Runs

    public var hasRepeats: Bool {
        verseRuns != .finite(1) || listRuns != .finite(1)
    }
}

extension AudioPreferences {
    // MARK: Public

    /// `nil` when nothing was saved, or the saved verses aren't in `quran`.
    public func lastPlaybackRange(in quran: Quran) -> LastPlaybackRange? {
        let preferences = Preferences.shared
        guard let startSura = preferences.valueForKey(Self.lastPlayStartSura),
              let startAyah = preferences.valueForKey(Self.lastPlayStartAyah),
              let endSura = preferences.valueForKey(Self.lastPlayEndSura),
              let endAyah = preferences.valueForKey(Self.lastPlayEndAyah),
              let start = AyahNumber(quran: quran, sura: startSura, ayah: startAyah),
              let end = AyahNumber(quran: quran, sura: endSura, ayah: endAyah)
        else {
            return nil
        }
        return LastPlaybackRange(
            start: start,
            end: end,
            verseRuns: Self.runs(androidRepeat: preferences.valueForKey(Self.lastPlayVerseRepeat)),
            listRuns: Self.runs(androidRepeat: preferences.valueForKey(Self.lastPlayRangeRepeat))
        )
    }

    public func saveLastPlaybackRange(_ range: LastPlaybackRange) {
        let preferences = Preferences.shared
        preferences.setValue(range.start.sura.suraNumber, forKey: Self.lastPlayStartSura)
        preferences.setValue(range.start.ayah, forKey: Self.lastPlayStartAyah)
        preferences.setValue(range.end.sura.suraNumber, forKey: Self.lastPlayEndSura)
        preferences.setValue(range.end.ayah, forKey: Self.lastPlayEndAyah)
        preferences.setValue(Self.androidRepeat(range.verseRuns), forKey: Self.lastPlayVerseRepeat)
        preferences.setValue(Self.androidRepeat(range.listRuns), forKey: Self.lastPlayRangeRepeat)
    }

    // MARK: Internal

    // quran_android's keys and counts, where a count is the plays after the first and -1 loops, so a backup carries over.
    static let lastPlayStartSura = PreferenceKey<Int?>(key: "lastPlayStartSura", defaultValue: nil)
    static let lastPlayStartAyah = PreferenceKey<Int?>(key: "lastPlayStartAyah", defaultValue: nil)
    static let lastPlayEndSura = PreferenceKey<Int?>(key: "lastPlayEndSura", defaultValue: nil)
    static let lastPlayEndAyah = PreferenceKey<Int?>(key: "lastPlayEndAyah", defaultValue: nil)
    static let lastPlayVerseRepeat = PreferenceKey<Int>(key: "lastPlayVerseRepeat", defaultValue: 0)
    static let lastPlayRangeRepeat = PreferenceKey<Int>(key: "lastPlayRangeRepeat", defaultValue: 0)

    // MARK: Private

    private static func androidRepeat(_ runs: Runs) -> Int {
        switch runs {
        case .finite(let count): count - 1
        case .indefinite: -1
        }
    }

    private static func runs(androidRepeat: Int) -> Runs {
        androidRepeat < 0 ? .indefinite : .finite(androidRepeat + 1)
    }
}
