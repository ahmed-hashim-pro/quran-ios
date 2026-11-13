import AdvancedAudioOptionsFeature
import AnalyticsFake
import AVFoundation
import BatchDownloaderFake
import Foundation
import QuranAudio
import QuranKit
import ReciterListFeature
import ReciterService
import ReciterServiceFake
import SystemDependenciesFake
import XCTest
@testable import AudioBannerFeature
@testable import QueuePlayer
@testable import QuranAudioKit

/// A banner view model on real services, with fakes only at the player, file system, network and bundle.
@MainActor
final class AudioBannerHarness {
    // MARK: Lifecycle

    init(pages: [Page], beforeStart: (AudioBannerViewModel) -> Void = { _ in }) async {
        let bundle = SystemBundleFake()
        bundle.arrays["reciters.plist"] = [reciter.toPlistDictionary()] as NSArray
        let (downloadManager, _) = await downloads.makeDownloader()
        downloader = QuranAudioDownloader(baseURL: URL(validURL: "https://example.com"), downloader: downloadManager, fileSystem: fileSystem)
        listener = AudioBannerListenerFake(visiblePages: pages)
        viewModel = AudioBannerViewModel(
            analytics: AnalyticsLibrarySpy(),
            reciterRetreiver: ReciterDataRetriever(bundle: bundle),
            recentRecitersService: RecentRecitersService(),
            audioPlayer: QuranAudioPlayer(player: player),
            downloader: downloader,
            reciterListBuilder: ReciterListBuilder(),
            advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder(),
            networkConnection: network
        )
        viewModel.listener = listener
        ReciterPreferences.shared.lastSelectedReciterId = reciter.id
        beforeStart(viewModel)
        await viewModel.start()
    }

    // MARK: Internal

    let reciter = Reciter.gappedReciter
    let player = QueuingPlayerFake()
    let fileSystem = FileSystemFake()
    let network = NetworkConnectionFake(onWiFi: true)
    let listener: AudioBannerListenerFake
    let downloader: QuranAudioDownloader
    private(set) var viewModel: AudioBannerViewModel!

    var bannerState: BannerStateSummary {
        switch viewModel.audioBannerState {
        case .playing(let paused, _, _, _): paused ? .paused : .playing
        case .readyToPlay: .readyToPlay
        case .downloading: .downloading
        case .confirmingDownload: .confirmingDownload
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
    case confirmingDownload
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
    private(set) var plays = 0

    func play(request: AudioRequest, rate: Float) {
        self.request = request
        plays += 1
    }

    func pause() {}
    func resume() {}

    /// Reports the end as the real player does, once someone is listening.
    func stop() {
        request = nil
        actions?.playbackEnded()
    }

    /// Reports the frame as the real player does when it reaches it.
    func reach(file: Int, frame: Int) {
        actions?.audioFrameChanged(file, frame, AVPlayerItem(url: URL(fileURLWithPath: "/dev/null")), nil)
    }

    func stepForward() {}
    func stepBackward() {}
    func setRate(_ rate: Float) {}

    func setFrameRuns(_ runs: Runs) {
        request = request?.withFrameRuns(runs)
    }

    func setRepeats(frameRuns: Runs, requestRuns: Runs, verseDelay: VerseDelay, repetitionDelay: RepetitionDelay) {
        request = request?.withRepeats(
            frameRuns: frameRuns, requestRuns: requestRuns, verseDelay: verseDelay, repetitionDelay: repetitionDelay
        )
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
