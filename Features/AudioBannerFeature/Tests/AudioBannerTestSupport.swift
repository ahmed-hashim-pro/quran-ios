import AdvancedAudioOptionsFeature
import AnalyticsFake
import BatchDownloaderFake
import Foundation
import QueuePlayer
import QuranAudio
import QuranKit
import ReciterListFeature
import ReciterService
import ReciterServiceFake
import SystemDependenciesFake
import XCTest
@testable import AudioBannerFeature
@testable import QuranAudioKit

/// A banner view model on real services, with fakes only at the player, file system, network and bundle.
@MainActor
final class AudioBannerHarness {
    // MARK: Lifecycle

    init(pages: [Page]) async {
        let bundle = SystemBundleFake()
        bundle.arrays["reciters.plist"] = [reciter.toPlistDictionary()] as NSArray
        let (downloadManager, _) = await downloads.makeDownloader()
        listener = AudioBannerListenerFake(visiblePages: pages)
        viewModel = AudioBannerViewModel(
            analytics: AnalyticsLibrarySpy(),
            reciterRetreiver: ReciterDataRetriever(bundle: bundle),
            recentRecitersService: RecentRecitersService(),
            audioPlayer: QuranAudioPlayer(player: player),
            downloader: QuranAudioDownloader(baseURL: URL(validURL: "https://example.com"), downloader: downloadManager, fileSystem: fileSystem),
            reciterListBuilder: ReciterListBuilder(),
            advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder()
        )
        viewModel.listener = listener
        ReciterPreferences.shared.lastSelectedReciterId = reciter.id
        await viewModel.start()
    }

    // MARK: Internal

    let reciter = Reciter.gappedReciter
    let player = QueuingPlayerFake()
    let fileSystem = FileSystemFake()
    let listener: AudioBannerListenerFake
    private(set) var viewModel: AudioBannerViewModel!

    var bannerState: BannerStateSummary {
        switch viewModel.audioBannerState {
        case .playing(let paused, _): paused ? .paused : .playing
        case .readyToPlay: .readyToPlay
        case .downloading: .downloading
        }
    }

    // MARK: Private

    private let downloads = BatchDownloaderFake.makeContext()
}

enum BannerStateSummary: Equatable {
    case playing
    case paused
    case readyToPlay
    case downloading
}

@MainActor
final class AudioBannerListenerFake: AudioBannerListener {
    init(visiblePages: [Page]) {
        self.visiblePages = visiblePages
    }

    var visiblePages: [Page]

    func highlightReadingAyah(_ ayah: AyahNumber?) {}
}

/// Holds the request it was asked to play instead of playing it.
@MainActor
final class QueuingPlayerFake: QueuingPlayer {
    var actions: QueuePlayerActions?
    private(set) var request: AudioRequest?

    func play(request: AudioRequest, rate: Float) {
        self.request = request
    }

    func pause() {}
    func resume() {}

    func stop() {
        request = nil
    }

    func stepForward() {}
    func stepBackward() {}
    func setRate(_ rate: Float) {}

    func setFrameRuns(_ runs: Runs) {
        request = request?.withFrameRuns(runs)
    }
}

/// Restores the preferences a test changes, since they live in the shared user defaults.
final class UserDefaultsSnapshot {
    init(keys: [String]) {
        self.keys = keys
        for key in keys {
            values[key] = UserDefaults.standard.object(forKey: key)
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    func restore() {
        for key in keys {
            if let value = values[key] {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    private let keys: [String]
    private var values: [String: Any] = [:]
}

@MainActor
func eventually(
    timeout: TimeInterval = 5,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ condition: @MainActor () -> Bool
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        guard Date() < deadline else {
            XCTFail("Condition not met in \(timeout) s", file: file, line: line)
            return
        }
        try await Task.sleep(nanoseconds: 10_000_000)
    }
}
