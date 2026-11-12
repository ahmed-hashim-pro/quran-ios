//
//  LastPlaybackRangePreferenceTests.swift
//

import Foundation
import QuranAudio
import QuranKit
import XCTest
@testable import QuranAudioKit

final class LastPlaybackRangePreferenceTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        for key in keys {
            originalValues[key] = UserDefaults.standard.object(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    override func tearDown() {
        for key in keys {
            if let value = originalValues[key] {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        super.tearDown()
    }

    func test_nothingSaved_hasNoRange() {
        XCTAssertNil(preferences.lastPlaybackRange(in: quran))
    }

    func test_savedRange_readsBackWithItsRepeats() {
        for (verseRuns, listRuns) in [(Runs.finite(1), Runs.finite(1)), (.finite(3), .indefinite), (.indefinite, .finite(2))] {
            let range = LastPlaybackRange(start: ayah(2, 255), end: ayah(3, 4), verseRuns: verseRuns, listRuns: listRuns)
            preferences.saveLastPlaybackRange(range)
            XCTAssertEqual(preferences.lastPlaybackRange(in: quran), range)
        }
    }

    func test_savedRange_usesAndroidsKeysAndCounts() {
        // quran_android stores the plays after the first, and -1 for a loop.
        let range = LastPlaybackRange(start: ayah(2, 255), end: ayah(3, 4), verseRuns: .finite(3), listRuns: .indefinite)
        preferences.saveLastPlaybackRange(range)

        let stored = keys.map { UserDefaults.standard.object(forKey: $0) as? Int }
        XCTAssertEqual(stored, [2, 255, 3, 4, 2, -1])
    }

    func test_androidsStoredRange_readsWithItsRepeats() {
        for (key, value) in zip(keys, [36, 1, 36, 12, 0, 4]) {
            UserDefaults.standard.set(value, forKey: key)
        }
        XCTAssertEqual(
            preferences.lastPlaybackRange(in: quran),
            LastPlaybackRange(start: ayah(36, 1), end: ayah(36, 12), verseRuns: .finite(1), listRuns: .finite(5))
        )
    }

    func test_aRangeOutsideThePrint_isNoRange() {
        for (key, value) in zip(keys, [1, 1, 1, 99, 0, 0]) {
            UserDefaults.standard.set(value, forKey: key)
        }
        XCTAssertNil(preferences.lastPlaybackRange(in: quran))
    }

    // MARK: Private

    private let keys = [
        "lastPlayStartSura", "lastPlayStartAyah", "lastPlayEndSura", "lastPlayEndAyah",
        "lastPlayVerseRepeat", "lastPlayRangeRepeat",
    ]
    private var originalValues: [String: Any] = [:]
    private let preferences = AudioPreferences.shared
    private let quran = Quran.hafsMadani1405

    private func ayah(_ sura: Int, _ ayah: Int) -> AyahNumber {
        AyahNumber(quran: quran, sura: sura, ayah: ayah)!
    }
}
