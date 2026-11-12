import AdvancedAudioOptionsFeature
import QuranAudio
import QuranKit
import XCTest
@testable import AudioBannerFeature
@testable import QuranAudioKit
@testable import UIx

@MainActor
final class AudioBannerViewModelTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        preferences = UserDefaultsSnapshot(keys: Self.preferenceKeys)
    }

    override func tearDown() async throws {
        preferences.restore()
        try await super.tearDown()
    }

    // MARK: - Repeat

    func test_repeatButton_cyclesThePlayingVersesRepeatsWithoutSavingThem() async throws {
        AudioPreferences.shared.streamingEnabled = true
        let sut = await AudioBannerHarness(pages: [midSuraPage])
        sut.viewModel.playFromBanner()
        try await eventually { sut.player.request != nil }

        var cycle: [Runs?] = []
        for _ in 0 ..< 5 {
            sut.viewModel.cycleRepeatFromBanner()
            cycle.append(sut.player.request?.frameRuns)
        }

        XCTAssertEqual(cycle, [.finite(2), .finite(3), .finite(4), .indefinite, .finite(1)])
        sut.viewModel.cycleRepeatFromBanner()
        XCTAssertEqual(sut.viewModel.audioOptionsSummary.verseRuns, .finite(2))
        XCTAssertEqual(AudioPreferences.shared.verseRuns, .finite(1))
    }

    // MARK: - Where to Start

    func test_play_onAPageWithSeveralSurahStarts_asksWhereToStart() async {
        let sut = await AudioBannerHarness(pages: [quran.pages.last!])

        sut.viewModel.playFromBanner()

        XCTAssertEqual(sut.viewModel.modalRequest?.owner, "playback_start")
        XCTAssertEqual(sut.viewModel.modalRequest?.kind, "sheet")
        XCTAssertNil(sut.player.request)
    }

    func test_play_onAPageARememberedRangeCovers_asksWhereToStart() async {
        AudioPreferences.shared.saveLastPlaybackRange(LastPlaybackRange(
            start: midSuraPage.firstVerse, end: quran.pages[3].firstVerse, verseRuns: .finite(2), listRuns: .finite(1)
        ))
        let sut = await AudioBannerHarness(pages: [midSuraPage])

        sut.viewModel.playFromBanner()

        XCTAssertEqual(sut.viewModel.modalRequest?.owner, "playback_start")
    }

    func test_play_onAPageWithOnePlaceToStart_playsTheWholePage() async throws {
        AudioPreferences.shared.streamingEnabled = true
        let sut = await AudioBannerHarness(pages: [midSuraPage])

        sut.viewModel.playFromBanner()

        try await eventually { sut.player.request != nil }
        XCTAssertNil(sut.viewModel.modalRequest)
    }

    func test_choosingTheRememberedRange_playsItWithItsRepeats() async throws {
        AudioPreferences.shared.streamingEnabled = true
        let sut = await AudioBannerHarness(pages: [midSuraPage])
        let start = midSuraPage.firstVerse
        let range = LastPlaybackRange(start: start, end: start.next!.next!, verseRuns: .finite(3), listRuns: .indefinite)

        sut.viewModel.play(from: .lastRange(range))

        try await eventually { sut.player.request != nil }
        XCTAssertEqual(sut.player.request?.files.count, 3)
        XCTAssertEqual(sut.player.request?.frameRuns, .finite(3))
        XCTAssertEqual(sut.player.request?.requestRuns, .indefinite)
        XCTAssertEqual(AudioPreferences.shared.verseRuns, .finite(1), "Playing the remembered range leaves the saved repeats alone")
    }

    func test_playingFromTheAudioOptions_remembersTheRange() async {
        AudioPreferences.shared.streamingEnabled = true
        let sut = await AudioBannerHarness(pages: [midSuraPage])
        let start = midSuraPage.firstVerse
        let end = start.next!

        sut.viewModel.updateAudioOptions(to: AdvancedAudioOptions(
            reciter: sut.reciter, start: start, end: end,
            verseRuns: .finite(2), listRuns: .finite(3), verseDelay: .none, repetitionDelay: .oneSecond
        ))

        XCTAssertEqual(
            AudioPreferences.shared.lastPlaybackRange(in: quran),
            LastPlaybackRange(start: start, end: end, verseRuns: .finite(2), listRuns: .finite(3))
        )
    }

    func test_playingAPage_keepsTheRememberedRange() async throws {
        AudioPreferences.shared.streamingEnabled = true
        let range = LastPlaybackRange(
            start: quran.suras[35].firstVerse, end: quran.suras[35].lastVerse, verseRuns: .finite(2), listRuns: .finite(1)
        )
        AudioPreferences.shared.saveLastPlaybackRange(range)
        let sut = await AudioBannerHarness(pages: [midSuraPage])

        sut.viewModel.playFromBanner()
        try await eventually { sut.player.request != nil }

        XCTAssertEqual(AudioPreferences.shared.lastPlaybackRange(in: quran), range)
    }

    // MARK: Private

    private static let preferenceKeys = [
        "audioStreamingEnabled", "audioVerseRuns", "audioListRuns", "audioPlaybackRate",
        "LastSelectedQariId", "recentRecitersIdsKey", "audioVerseDelay", "audioRepetitionDelay",
        "lastPlayStartSura", "lastPlayStartAyah", "lastPlayEndSura", "lastPlayEndAyah",
        "lastPlayVerseRepeat", "lastPlayRangeRepeat",
    ]

    private var preferences: UserDefaultsSnapshot!
    private let quran = Quran.hafsMadani1405

    /// Starts and ends inside Al-Baqarah.
    private var midSuraPage: Page { quran.pages[2] }
}
