import AdvancedAudioOptionsFeature
import Localization
import QueuePlayer
import QuranAudio
import QuranKit
import QuranLocalization
import ReciterService
import ReciterServiceFake
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

    // MARK: - Now Playing

    func test_playingAnAyah_namesItsSurahAndNumber() async throws {
        AudioPreferences.shared.streamingEnabled = true
        let sut = await AudioBannerHarness(pages: [midSuraPage])
        sut.viewModel.playFromBanner()
        try await eventually { sut.bannerState == .playing }

        sut.player.reach(file: 1, frame: 0)

        let ayah = midSuraPage.firstVerse.next!
        XCTAssertEqual(
            sut.viewModel.nowPlaying?.accessibilityText,
            lFormat("audiobar_now_playing", table: .android, ayah.sura.localizedName(), NumberFormatter.shared.format(ayah.ayah))
        )
    }

    func test_stopping_clearsTheSurahAndAyah() async throws {
        AudioPreferences.shared.streamingEnabled = true
        let sut = await AudioBannerHarness(pages: [midSuraPage])
        sut.viewModel.playFromBanner()
        try await eventually { sut.bannerState == .playing }
        sut.player.reach(file: 0, frame: 0)
        XCTAssertNotNil(sut.viewModel.nowPlaying)

        sut.viewModel.stopFromBanner()

        XCTAssertNil(sut.viewModel.nowPlaying)
        XCTAssertEqual(sut.bannerState, .readyToPlay)
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

    // MARK: - Audio Options

    func test_applyingTheOptionsToThePlayingRange_changesItsRepeatsWithoutRestarting() async throws {
        AudioPreferences.shared.streamingEnabled = true
        let sut = await AudioBannerHarness(pages: [midSuraPage])
        sut.viewModel.playFromBanner()
        try await eventually { sut.bannerState == .playing }
        var options = try XCTUnwrap(sut.viewModel.audioOptionsToShow())

        options.verseRuns = .finite(3)
        options.listRuns = .indefinite
        options.verseDelay = .half
        sut.viewModel.updateAudioOptions(to: options)

        XCTAssertEqual(sut.player.plays, 1)
        XCTAssertEqual(sut.player.request?.frameRuns, .finite(3))
        XCTAssertEqual(sut.player.request?.requestRuns, .indefinite)
        XCTAssertEqual(sut.player.request?.verseDelay, .half)
        XCTAssertEqual(sut.viewModel.audioOptionsSummary.verseRuns, .finite(3))
        XCTAssertEqual(sut.bannerState, .playing)
    }

    func test_applyingTheOptionsToAnotherRange_playsItFromItsStart() async throws {
        AudioPreferences.shared.streamingEnabled = true
        let sut = await AudioBannerHarness(pages: [midSuraPage])
        sut.viewModel.playFromBanner()
        try await eventually { sut.bannerState == .playing }
        var options = try XCTUnwrap(sut.viewModel.audioOptionsToShow())

        options.end = options.start.next!
        sut.viewModel.updateAudioOptions(to: options)

        try await eventually { sut.player.plays == 2 }
        XCTAssertEqual(sut.player.request?.files.count, 2)
    }

    func test_optionsWhileStopped_showTheRememberedRangeCoveringThePage() async throws {
        let start = midSuraPage.firstVerse
        let range = LastPlaybackRange(start: start, end: quran.pages[3].firstVerse, verseRuns: .finite(2), listRuns: .finite(3))
        AudioPreferences.shared.saveLastPlaybackRange(range)
        let sut = await AudioBannerHarness(pages: [midSuraPage])

        let options = try XCTUnwrap(sut.viewModel.audioOptionsToShow())

        XCTAssertEqual(options.start, range.start)
        XCTAssertEqual(options.end, range.end)
        XCTAssertEqual(options.verseRuns, .finite(2))
        XCTAssertEqual(options.listRuns, .finite(3))
    }

    func test_optionsWhileStopped_showThePageWhenNoRememberedRangeCoversIt() async throws {
        AudioPreferences.shared.saveLastPlaybackRange(LastPlaybackRange(
            start: quran.suras[35].firstVerse, end: quran.suras[35].lastVerse, verseRuns: .finite(2), listRuns: .finite(1)
        ))
        let sut = await AudioBannerHarness(pages: [midSuraPage])

        let options = try XCTUnwrap(sut.viewModel.audioOptionsToShow())

        XCTAssertEqual(options.start, midSuraPage.firstVerse)
        XCTAssertEqual(options.verseRuns, AudioPreferences.shared.verseRuns)
    }

    // MARK: - Reciter

    func test_choosingAReciterWhilePlaying_keepsTheRecitationGoingForTheNextPlay() async throws {
        AudioPreferences.shared.streamingEnabled = true
        let sut = await AudioBannerHarness(pages: [midSuraPage])
        sut.viewModel.playFromBanner()
        try await eventually { sut.bannerState == .playing }
        let request = sut.player.request

        sut.viewModel.onSelectedReciterChanged(to: .gaplessReciter)

        XCTAssertEqual(sut.bannerState, .playing)
        XCTAssertEqual(sut.player.request, request)
        XCTAssertEqual(sut.player.plays, 1)
        XCTAssertEqual(ReciterPreferences.shared.lastSelectedReciterId, Reciter.gaplessReciter.id)
    }

    // MARK: - Downloading off Wi-Fi

    func test_play_offWiFi_asksBeforeDownloading() async throws {
        let sut = await AudioBannerHarness(pages: [midSuraPage])
        sut.network.onWiFi = false

        sut.viewModel.playFromBanner()

        try await eventually { sut.bannerState == .confirmingDownload }
        let downloads = await sut.downloader.runningAudioDownloads()
        XCTAssertTrue(downloads.isEmpty)
        XCTAssertNil(sut.player.request)
    }

    func test_acceptingTheDownloadOffWiFi_downloadsWithoutAskingAgain() async throws {
        let sut = await AudioBannerHarness(pages: [midSuraPage])
        sut.network.onWiFi = false
        sut.viewModel.playFromBanner()
        try await eventually { sut.bannerState == .confirmingDownload }

        sut.viewModel.acceptDownloadFromBanner()

        try await eventually { sut.bannerState == .downloading }
        var downloads = await sut.downloader.runningAudioDownloads()
        for _ in 0 ..< 100 where downloads.isEmpty {
            try await Task.sleep(nanoseconds: 10_000_000)
            downloads = await sut.downloader.runningAudioDownloads()
        }
        XCTAssertEqual(downloads.count, 1)
        XCTAssertEqual(sut.bannerState, .downloading)
    }

    func test_decliningTheDownloadOffWiFi_stops() async throws {
        let sut = await AudioBannerHarness(pages: [midSuraPage])
        sut.network.onWiFi = false
        sut.viewModel.playFromBanner()
        try await eventually { sut.bannerState == .confirmingDownload }

        sut.viewModel.declineDownloadFromBanner()

        XCTAssertEqual(sut.bannerState, .readyToPlay)
        let downloads = await sut.downloader.runningAudioDownloads()
        XCTAssertTrue(downloads.isEmpty)
    }

    func test_play_onWiFi_downloadsWithoutAsking() async throws {
        let sut = await AudioBannerHarness(pages: [midSuraPage])

        sut.viewModel.playFromBanner()

        try await eventually { sut.bannerState == .downloading }
    }

    func test_streamingOffWiFi_playsWithoutAsking() async throws {
        AudioPreferences.shared.streamingEnabled = true
        let sut = await AudioBannerHarness(pages: [midSuraPage])
        sut.network.onWiFi = false

        sut.viewModel.playFromBanner()

        try await eventually { sut.player.request != nil }
        XCTAssertEqual(sut.bannerState, .playing)
    }

    // MARK: - Playing on Open

    func test_playOnOpen_streamsTheOpenPageWithStreamingOff() async throws {
        let sut = await AudioBannerHarness(pages: [midSuraPage]) { $0.playOnOpen() }
        sut.network.onWiFi = false

        try await eventually { sut.player.request != nil }

        XCTAssertEqual(sut.bannerState, .playing)
        XCTAssertEqual(sut.player.request?.files.first?.url.isFileURL, false)
        XCTAssertFalse(AudioPreferences.shared.streamingEnabled)
    }

    func test_playOnOpen_playsOnlyOnce() async throws {
        let sut = await AudioBannerHarness(pages: [midSuraPage]) { $0.playOnOpen() }
        try await eventually { sut.player.request != nil }
        sut.viewModel.stopFromBanner()
        XCTAssertEqual(sut.bannerState, .readyToPlay)

        sut.viewModel.playFromBanner()

        try await eventually { sut.bannerState == .downloading }
    }

    func test_playOnOpen_onAPageWithSeveralSurahStarts_asksWhereToStartWithoutStreaming() async throws {
        let page = quran.pages.last!
        let sut = await AudioBannerHarness(pages: [page]) { $0.playOnOpen() }
        try await eventually { sut.viewModel.modalRequest?.owner == "playback_start" }

        sut.viewModel.play(from: .sura(page.startSura))

        try await eventually { sut.bannerState == .downloading }
        XCTAssertNil(sut.player.request)
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
