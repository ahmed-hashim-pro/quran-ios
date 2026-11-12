import QuranAudio
import QuranAudioKit
import QuranKit
import XCTest
@testable import AudioBannerFeature

final class PlaybackStartTests: XCTestCase {
    // MARK: Internal

    func test_aPageStartingNoSurah_playsWithoutAsking() {
        XCTAssertEqual(PlaybackStart.choices(on: quran.pages[2], lastRange: nil), [])
    }

    func test_aPageOpeningWithItsOnlySurah_playsWithoutAsking() {
        let baqarah = quran.suras[1]
        XCTAssertEqual(PlaybackStart.choices(on: baqarah.page, lastRange: nil), [])
    }

    func test_aPageWithSeveralSurahStarts_offersEachSurah() {
        let page = quran.pages.last!
        XCTAssertEqual(page.startSura, quran.suras[111])

        XCTAssertEqual(
            PlaybackStart.choices(on: page, lastRange: nil),
            [.sura(quran.suras[111]), .sura(quran.suras[112]), .sura(quran.suras[113])]
        )
    }

    func test_aSurahStartingPartWayDownThePage_alsoOffersThePagesStart() {
        let maidah = quran.suras[4]
        let page = maidah.page
        XCTAssertEqual(page.startSura, quran.suras[3], "Al-Ma'idah should start below the end of An-Nisa'")

        XCTAssertEqual(PlaybackStart.choices(on: page, lastRange: nil), [.page(page), .sura(maidah)])
    }

    func test_aRememberedRangeCoveringThePage_isOfferedFirst() {
        let page = quran.pages[2]
        let range = LastPlaybackRange(start: page.firstVerse, end: quran.pages[4].firstVerse, verseRuns: .finite(3), listRuns: .finite(1))

        XCTAssertEqual(PlaybackStart.choices(on: page, lastRange: range), [.lastRange(range), .page(page)])
    }

    func test_aRememberedRangeCoveringAPageOpeningWithASurah_offersItAndTheSurah() {
        let baqarah = quran.suras[1]
        let range = LastPlaybackRange(start: baqarah.firstVerse, end: baqarah.lastVerse, verseRuns: .finite(1), listRuns: .indefinite)

        XCTAssertEqual(PlaybackStart.choices(on: baqarah.page, lastRange: range), [.lastRange(range), .sura(baqarah)])
    }

    func test_aRememberedRangeElsewhere_isNotOffered() {
        let range = LastPlaybackRange(
            start: quran.suras[35].firstVerse, end: quran.suras[35].lastVerse,
            verseRuns: .finite(2), listRuns: .finite(2)
        )
        XCTAssertEqual(PlaybackStart.choices(on: quran.pages[2], lastRange: range), [])
    }

    func test_rememberedRange_coversThePagesBetweenItsEnds() {
        let range = LastPlaybackRange(
            start: quran.pages[2].firstVerse, end: quran.pages[4].firstVerse, verseRuns: .finite(2), listRuns: .finite(1)
        )

        XCTAssertNil(PlaybackStart.rememberedRange(covering: quran.pages[1], lastRange: range))
        XCTAssertEqual(PlaybackStart.rememberedRange(covering: quran.pages[3], lastRange: range), range)
        XCTAssertEqual(PlaybackStart.rememberedRange(covering: quran.pages[4], lastRange: range), range)
        XCTAssertNil(PlaybackStart.rememberedRange(covering: quran.pages[5], lastRange: range))
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405
}
