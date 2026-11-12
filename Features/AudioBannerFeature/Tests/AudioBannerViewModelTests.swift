import QuranAudio
import QuranKit
import XCTest
@testable import AudioBannerFeature
@testable import QuranAudioKit

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

    // MARK: Private

    private static let preferenceKeys = [
        "audioStreamingEnabled", "audioVerseRuns", "audioListRuns", "audioPlaybackRate",
        "LastSelectedQariId", "recentRecitersIdsKey",
    ]

    private var preferences: UserDefaultsSnapshot!
    private let quran = Quran.hafsMadani1405

    /// Starts and ends inside Al-Baqarah.
    private var midSuraPage: Page { quran.pages[2] }
}
