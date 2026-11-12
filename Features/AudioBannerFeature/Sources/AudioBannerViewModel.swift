//
//  AudioBannerViewModel.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AdvancedAudioOptionsFeature
import Analytics
import BatchDownloader
import Crashing
import Foundation
import Localization
import NoorUI
import QueuePlayer
import QuranAudio
import QuranAudioKit
import QuranKit
import ReciterListFeature
import ReciterService
import SwiftUI
import SystemDependencies
import UIKit
import UIx
import Utilities
import VLogging

@MainActor
public protocol AudioBannerListener: AnyObject {
    var visiblePages: [Page] { get }
    func highlightReadingAyah(_ ayah: AyahNumber?)
}

private enum PlaybackState {
    case playing
    case paused
    case stopped
    case downloading(progress: Double)
    case confirmingDownload

    var crashContextValue: String {
        switch self {
        case .playing: "playing"
        case .paused: "paused"
        case .stopped: "stopped"
        case .downloading: "downloading"
        case .confirmingDownload: "confirming_download"
        }
    }
}

@MainActor
public final class AudioBannerViewModel: ObservableObject {
    typealias AudioRange = (start: AyahNumber, end: AyahNumber)

    // MARK: Lifecycle

    init(
        analytics: AnalyticsLibrary,
        reciterRetreiver: ReciterDataRetriever,
        recentRecitersService: RecentRecitersService,
        audioPlayer: QuranAudioPlayer,
        downloader: QuranAudioDownloader,
        reciterListBuilder: ReciterListBuilder,
        advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder,
        networkConnection: NetworkConnection
    ) {
        self.analytics = analytics
        self.reciterRetreiver = reciterRetreiver
        self.recentRecitersService = recentRecitersService
        self.audioPlayer = audioPlayer
        self.downloader = downloader
        self.reciterListBuilder = reciterListBuilder
        self.advancedAudioOptionsBuilder = advancedAudioOptionsBuilder
        self.networkConnection = networkConnection
        playbackRate = AudioPreferences.shared.playbackRate
        crashContext.setAudioState(playingState.crashContextValue)
        crashContext.setAudioReciter(id: nil)
        crashContext.clearPlayingAyah()
        crashContext.setAdvancedAudioOptionsPhase("idle")

        setUpAudioPlayerActions()
        setUpRemoteCommandHandler()

        AudioPreferences.shared.$playbackRate.assign(to: &$playbackRate)
    }

    // MARK: Public

    public func play(from: AyahNumber, to: AyahNumber?, repeatVerses: Bool) {
        logger.info("AudioBanner: playing from \(from) to \(String(describing: to))")
        analytics.playFrom(menu: true)
        play(
            from: from,
            to: to,
            verseRuns: AudioPreferences.shared.verseRuns,
            listRuns: repeatVerses ? .indefinite : AudioPreferences.shared.listRuns,
            playbackRate: playbackRate,
            verseDelay: AudioPreferences.shared.verseDelay,
            repetitionDelay: AudioPreferences.shared.repetitionDelay
        )
    }

    /// quran_android's Home Read & listen: once the reader is up, Play the open page once, streamed so
    /// nothing waits on a download. Asking where to start drops the streaming, as Android does.
    public func playOnOpen() {
        playsOnOpen = true
        if hasStarted {
            schedulePlayOnOpen()
        }
    }

    // MARK: Internal

    weak var listener: AudioBannerListener?

    @Published var error: Error?
    @Published var toast: (message: MultipartText, action: ToastAction?)?
    @Published var modalRequest: ModalPresentationRequest?
    @Published var playbackRate: Float

    var audioOptionsSummary: AudioOptionsSummary {
        if case .stopped = playingState {
            return AudioOptionsSummary(
                rate: playbackRate,
                verseRuns: AudioPreferences.shared.verseRuns,
                rangeRuns: AudioPreferences.shared.listRuns
            )
        }
        return AudioOptionsSummary(rate: playbackRate, verseRuns: verseRuns, rangeRuns: listRuns)
    }

    var audioBannerState: AudioBannerState {
        switch playingState {
        case .playing: .playing(paused: false, rate: playbackRate)
        case .paused: .playing(paused: true, rate: playbackRate)
        case .stopped: .readyToPlay(reciter: selectedReciter?.localizedName ?? "")
        case .downloading(let progress): .downloading(progress: progress)
        case .confirmingDownload: .confirmingDownload
        }
    }

    func start() async {
        remoteCommandsHandler?.startListeningToPlayCommand()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        reciters = await reciterRetreiver.getReciters()
        logger.info("AudioBanner: reciters loaded")

        let runningDownloads = await downloader.runningAudioDownloads()
        logger.info("AudioBanner: loaded runningAudioDownloads count: \(runningDownloads.count)")

        if runningDownloads.isEmpty {
            playingState = .stopped
        } else {
            cancellableTasks.insert(
                Task {
                    await observe(runningDownloads)
                }.asCancellableTask()
            )
        }
        hasStarted = true
        if playsOnOpen {
            schedulePlayOnOpen()
        }
    }

    func updatePlaybackRate(to rate: Float) {
        AudioPreferences.shared.playbackRate = rate
        audioPlayer.setRate(rate)
    }

    // MARK: Private

    private static let playbackStartOwner = "playback_start"

    private var audioRange: AudioRange?

    private let analytics: AnalyticsLibrary
    private let reciterRetreiver: ReciterDataRetriever
    private let recentRecitersService: RecentRecitersService
    private let preferences = ReciterPreferences.shared
    private let lastAyahFinder: LastAyahFinder = PreferencesLastAyahFinder.shared
    private let audioPlayer: QuranAudioPlayer
    private let downloader: QuranAudioDownloader
    private var remoteCommandsHandler: RemoteCommandsHandler?
    private let reciterListBuilder: ReciterListBuilder
    private let advancedAudioOptionsBuilder: AdvancedAudioOptionsBuilder
    private let networkConnection: NetworkConnection
    /// The play waiting for the user to allow downloading off Wi-Fi.
    private var playAllowingDownload: (() -> Void)?

    @Published private var verseRuns: Runs = AudioPreferences.shared.verseRuns
    @Published private var listRuns: Runs = AudioPreferences.shared.listRuns
    private var verseDelay: VerseDelay = AudioPreferences.shared.verseDelay
    private var repetitionDelay: RepetitionDelay = AudioPreferences.shared.repetitionDelay
    private var reciters: [Reciter] = []
    private var hasStarted = false
    private var playsOnOpen = false
    private var cancellableTasks: Set<CancellableTask> = []

    @Published private var playingState: PlaybackState = .stopped {
        didSet {
            crashContext.setAudioState(playingState.crashContextValue)
            logger.info("AudioBanner: playingState updated to \(playingState) - reciter: \(String(describing: selectedReciter?.id))")
            if case .stopped = playingState {
                onPlayingStateStopped()
            }
        }
    }

    private var selectedReciter: Reciter? {
        let storedSelectedReciterId = preferences.lastSelectedReciterId
        let selectedReciter = reciters.first { $0.id == storedSelectedReciterId }
        if selectedReciter == nil {
            let firstReciter = reciters.first
            logger.error("AudioBanner: couldn't find reciter \(storedSelectedReciterId) using \(String(describing: firstReciter?.id)) instead")
            return firstReciter
        }
        return selectedReciter
    }

    private func onPlayingStateStopped() {
        if let selectedReciter {
            crashContext.setAudioReciter(id: selectedReciter.id)
        } else {
            crashContext.setAudioReciter(id: nil)
        }
        listener?.highlightReadingAyah(nil)

        remoteCommandsHandler?.stopListening()
        remoteCommandsHandler?.startListeningToPlayCommand()
    }

    @objc
    private func applicationDidBecomeActive() {
        // re-assign playingState to update UI
        let tempPlayingState = playingState
        playingState = tempPlayingState
    }

    private func selectReciter(_ reciter: Reciter) {
        preferences.lastSelectedReciterId = reciter.id
    }

    // MARK: - Playback Controls

    private func schedulePlayOnOpen() {
        playsOnOpen = false
        cancellableTasks.task { [weak self] in
            // Android's delay, which also lets the reader finish appearing before a sheet can show.
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard let self, case .stopped = playingState else {
                return
            }
            logger.info("AudioBanner: playing the page the reader opened on")
            playCurrentPageOrAskWhere(forcingStream: true)
        }
    }

    private func playStartingCurrentPage(forcingStream: Bool = false) {
        guard let currentPage = listener?.visiblePages.min() else { return }
        logger.info("AudioBanner: Play starting page \(currentPage)")

        // start downloading & playing
        analytics.playFrom(menu: false)
        play(
            from: currentPage.firstVerse,
            to: nil,
            verseRuns: AudioPreferences.shared.verseRuns,
            listRuns: AudioPreferences.shared.listRuns,
            playbackRate: playbackRate,
            verseDelay: AudioPreferences.shared.verseDelay,
            repetitionDelay: AudioPreferences.shared.repetitionDelay,
            forcingStream: forcingStream
        )
    }

    /// quran_android asks where to start when the page holds more than one place to begin.
    private func playCurrentPageOrAskWhere(forcingStream: Bool = false) {
        guard let page = listener?.visiblePages.min() else { return }
        let choices = PlaybackStart.choices(on: page, lastRange: AudioPreferences.shared.lastPlaybackRange(in: page.quran))
        guard !choices.isEmpty else {
            playStartingCurrentPage(forcingStream: forcingStream)
            return
        }
        logger.info("AudioBanner: asking where to start playing page \(page)")
        let chooser = PlaybackStartChooserBuilder().build(
            reciter: selectedReciter?.localizedName ?? "",
            choices: choices,
            choose: { [weak self] in self?.play(from: $0) },
            close: { [weak self] in self?.modalRequest = .dismiss(owner: Self.playbackStartOwner) }
        )
        modalRequest = .present(chooser, owner: Self.playbackStartOwner, kind: "sheet")
    }

    private func setAudioRangeForCurrentPage() {
        guard let currentPage = listener?.visiblePages.min() else { return }
        let from = currentPage.firstVerse
        let end = lastAyahFinder.findLastAyah(startAyah: from)
        audioRange = (start: from, end: end)
    }

    private func play(
        from: AyahNumber,
        to: AyahNumber?,
        verseRuns: Runs,
        listRuns: Runs,
        playbackRate: Float,
        verseDelay: VerseDelay,
        repetitionDelay: RepetitionDelay,
        forcingStream: Bool = false,
        downloadsOffWiFi: Bool = false
    ) {
        guard let selectedReciter else {
            return
        }
        playAllowingDownload = nil
        audioPlayer.stopAudio()
        let end = to ?? lastAyahFinder.findLastAyah(startAyah: from)
        audioRange = (start: from, end: end)
        self.verseRuns = verseRuns
        self.listRuns = listRuns
        self.playbackRate = playbackRate
        self.verseDelay = verseDelay
        self.repetitionDelay = repetitionDelay

        recentRecitersService.updateRecentRecitersList(selectedReciter)

        let replayAllowingDownload: () -> Void = { [weak self] in
            self?.play(
                from: from, to: to, verseRuns: verseRuns, listRuns: listRuns, playbackRate: playbackRate,
                verseDelay: verseDelay, repetitionDelay: repetitionDelay, forcingStream: forcingStream, downloadsOffWiFi: true
            )
        }

        cancellableTasks.task { [weak self] in
            do {
                var streaming = AudioPreferences.shared.streamingEnabled
                if forcingStream, !streaming {
                    // As on Android, audio already on the device plays from it.
                    let downloaded = await self?.downloader.downloaded(reciter: selectedReciter, from: from, to: end) ?? true
                    streaming = !downloaded
                }

                if streaming {
                    // For gapless streaming, the timing database must still be available locally.
                    if case .gapless = selectedReciter.audioType {
                        let dbReady = self?.downloader.databaseDownloaded(reciter: selectedReciter) ?? true
                        logger.info("AudioBanner: streaming gapless – database ready? \(dbReady)")
                        if !dbReady {
                            guard await self?.mayDownload(offWiFi: downloadsOffWiFi, orAskThen: replayAllowingDownload) == true else {
                                return
                            }
                            self?.playingState = .downloading(progress: 0)
                            let download = try await self?.downloader.downloadDatabase(reciter: selectedReciter)
                            guard let download else {
                                logger.info("AudioBanner: couldn't create database download request")
                                return
                            }
                            await self?.observe([download])
                            logger.info("AudioBanner: database download completed")
                        }
                    }
                } else {
                    let downloaded = await self?.downloader.downloaded(reciter: selectedReciter, from: from, to: end) ?? true
                    logger.info("AudioBanner: reciter downloaded? \(downloaded)")
                    if !downloaded {
                        guard await self?.mayDownload(offWiFi: downloadsOffWiFi, orAskThen: replayAllowingDownload) == true else {
                            return
                        }
                        self?.startDownloading()
                        let download = try await self?.downloader.download(from: from, to: end, reciter: selectedReciter)
                        guard let download else {
                            logger.info("AudioBanner: couldn't create a download request")
                            return
                        }

                        await self?.observe([download])

                        for try await _ in download.progress { }

                        logger.info("AudioBanner: download completed")
                    }
                }

                guard let self else {
                    return
                }

                try await audioPlayer.play(
                    reciter: selectedReciter,
                    rate: playbackRate,
                    from: from, to: end,
                    verseRuns: verseRuns, listRuns: listRuns,
                    verseDelay: verseDelay,
                    repetitionDelay: repetitionDelay,
                    streaming: streaming
                )
                playingStarted()
            } catch {
                self?.playbackFailed(error)
            }
        }
    }

    private func togglePlayPause() {
        switch playingState {
        case .playing: pause()
        case .paused: resume()
        default:
            logger.error("Invalid playingState \(playingState) found while trying to pause/resume playback")
        }
    }

    private func pause() {
        playingState = .paused
        audioPlayer.pauseAudio()
    }

    private func resume() {
        playingState = .playing
        audioPlayer.resumeAudio()
    }

    private func stepForward() {
        audioPlayer.stepForward()
    }

    private func stepBackward() {
        audioPlayer.stepBackward()
    }

    private func stop() {
        playAllowingDownload = nil
        audioRange = nil
        audioPlayer.stopAudio()
    }

    // MARK: - Downloading

    /// quran_android asks before downloading off Wi-Fi, then plays the request again once the user agrees.
    private func mayDownload(offWiFi allowed: Bool, orAskThen playAllowingDownload: @escaping () -> Void) async -> Bool {
        if allowed {
            return true
        }
        if await networkConnection.isOnWiFi() {
            return true
        }
        logger.info("AudioBanner: asking before downloading off Wi-Fi")
        self.playAllowingDownload = playAllowingDownload
        playingState = .confirmingDownload
        return false
    }

    private func observe(_ downloads: [DownloadBatchResponse]) async {
        await updateDownloadProgress()
        await withTaskGroup(of: Void.self) { group in
            for download in downloads {
                group.addTask { [weak self] in
                    do {
                        for try await _ in download.progress {
                            if let self {
                                await updateDownloadProgress()
                            }
                        }
                    } catch {
                        // Ignore errors
                    }
                }
            }
        }
        playbackEnded()
    }

    // MARK: - Audio Interactor Delegate

    private func setUpAudioPlayerActions() {
        let actions = QuranAudioPlayerActions(
            playbackEnded: { [weak self] in self?.playbackEnded() },
            playbackPaused: { [weak self] in self?.playbackPaused() },
            playbackResumed: { [weak self] in self?.playbackResumed() },
            playing: { [weak self] in self?.playing(ayah: $0) }
        )
        audioPlayer.setActions(actions)
    }

    private func playbackPaused() {
        logger.info("AudioBanner: playback paused")
        updatePlayingState(to: .paused)
    }

    private func playbackResumed() {
        logger.info("AudioBanner: playback resumed")
        playingState = .playing
    }

    private func playing(ayah: AyahNumber) {
        logger.info("AudioBanner: playing verse \(ayah.nonLocalizedDescription)")
        crashContext.setPlayingAyah(sura: ayah.sura.suraNumber, ayah: ayah.ayah)
        listener?.highlightReadingAyah(ayah)
    }

    // MARK: - State changes

    private func updatePlayingState(to playingState: PlaybackState) {
        self.playingState = playingState
    }

    private func playbackEnded() {
        logger.info("AudioBanner: onPlaybackOrDownloadingCompleted")

        crashContext.clearPlayingAyah()
        playingState = .stopped
    }

    private func startDownloading() {
        logger.info("AudioBanner: will start downloading")
        playingState = .downloading(progress: 0)

        guard let audioRange else {
            return
        }
        let message = audioMessage("audio.downloading.message", audioRange: audioRange)
        toast = (message, action: nil)
    }

    private func updateDownloadProgress() async {
        let downloads = await downloader.runningAudioDownloads()
        let progress = downloads.map(\.currentProgress.progress).reduce(0, +)
        playingState = .downloading(progress: progress / Double(downloads.count))
    }

    private func playingStarted() {
        logger.info("AudioBanner: playing started")
        cancellableTasks = []
        remoteCommandsHandler?.startListening()
        playingState = .playing

        guard let audioRange else {
            return
        }

        let message = audioMessage("audio.playing.message", audioRange: audioRange)
        toast = (message, action: ToastAction(title: l("audio.playing.action.modify")) { [weak self] in
            self?.showAdvancedAudioOptions()
        })
    }

    private func playbackFailed(_ error: Error) {
        logger.info("AudioBanner: failed to playing audio. \(error)")
        self.error = error
        playbackEnded()
    }

    private func audioMessage(_ format: String, audioRange: AudioRange) -> MultipartText {
        let start: MultipartText = "\(ayah: audioRange.start)"
        let end: MultipartText = "\(ayah: audioRange.end)"
        return MultipartText.localizedFormat(format, start, end)
    }
}

extension AudioBannerViewModel {
    func playFromBanner() {
        logger.info("AudioBanner: play button tapped. State: \(playingState)")
        playCurrentPageOrAskWhere()
    }

    /// Plays from what the user chose in the sheet asking where to start.
    func play(from start: PlaybackStart) {
        logger.info("AudioBanner: chose to start playing from \(start)")
        modalRequest = .dismiss(owner: Self.playbackStartOwner)
        analytics.playFrom(menu: false)
        let preferences = AudioPreferences.shared
        let (from, to, verseRuns, listRuns): (AyahNumber, AyahNumber?, Runs, Runs) = switch start {
        case .lastRange(let range): (range.start, range.end, range.verseRuns, range.listRuns)
        case .page(let page): (page.firstVerse, nil, preferences.verseRuns, preferences.listRuns)
        case .sura(let sura): (sura.firstVerse, nil, preferences.verseRuns, preferences.listRuns)
        }
        play(
            from: from, to: to, verseRuns: verseRuns, listRuns: listRuns, playbackRate: playbackRate,
            verseDelay: preferences.verseDelay, repetitionDelay: preferences.repetitionDelay
        )
    }

    func pauseFromBanner() {
        logger.info("AudioBanner: pause button tapped. State: \(playingState)")
        pause()
    }

    func resumeFromBanner() {
        logger.info("AudioBanner: resume button tapped. State: \(playingState)")
        resume()
    }

    func stopFromBanner() {
        logger.info("AudioBanner: stop button tapped. State: \(playingState)")
        stop()
    }

    func forwardFromBanner() {
        logger.info("AudioBanner: step forward button tapped. State: \(playingState)")
        stepForward()
    }

    func backwardFromBanner() {
        logger.info("AudioBanner: step backward button tapped. State: \(playingState)")
        stepBackward()
    }

    /// Changes only the playing recitation, as quran_android's audio bar does, so the saved repeats stay.
    func cycleRepeatFromBanner() {
        let runs = verseRuns.nextAudioBarRepeat
        logger.info("AudioBanner: repeat button tapped, verse runs \(runs). State: \(playingState)")
        verseRuns = runs
        audioPlayer.setVerseRuns(runs)
    }

    func acceptDownloadFromBanner() {
        logger.info("AudioBanner: accept download tapped. State: \(playingState)")
        let play = playAllowingDownload
        playAllowingDownload = nil
        play?()
    }

    func declineDownloadFromBanner() {
        logger.info("AudioBanner: decline download tapped. State: \(playingState)")
        playAllowingDownload = nil
        playbackEnded()
    }

    func cancelDownload() async {
        logger.info("AudioBanner: cancel download tapped. State: \(playingState)")
        await downloader.cancelAllAudioDownloads()
        playbackEnded()
    }
}

extension AudioBannerViewModel {
    private func setUpRemoteCommandHandler() {
        let remoteActions = RemoteCommandActions(
            play: { [weak self] in self?.handlePlayCommand() },
            pause: { [weak self] in self?.handlePauseCommand() },
            togglePlayPause: { [weak self] in self?.handleTogglePlayPauseCommand() },
            nextTrack: { [weak self] in self?.handleNextTrackCommand() },
            previousTrack: { [weak self] in self?.handlePreviousTrackCommand() }
        )
        remoteCommandsHandler = RemoteCommandsHandler(center: .shared(), actions: remoteActions)
    }

    private func handlePlayCommand() {
        logger.info("AudioBanner: play command fired. State: \(playingState)")
        switch playingState {
        case .stopped: playStartingCurrentPage()
        case .paused, .playing: resume()
        case .downloading, .confirmingDownload: break
        }
    }

    private func handlePauseCommand() {
        logger.info("AudioBanner: pause command fired. State: \(playingState)")
        pause()
    }

    private func handleTogglePlayPauseCommand() {
        logger.info("AudioBanner: toggle play/pause command fired. State: \(playingState)")
        togglePlayPause()
    }

    private func handleNextTrackCommand() {
        logger.info("AudioBanner: step forward command fired. State: \(playingState)")
        stepForward()
    }

    private func handlePreviousTrackCommand() {
        logger.info("AudioBanner: step backward command fired. State: \(playingState)")
        stepBackward()
    }
}

extension AudioBannerViewModel: ReciterListListener {
    func presentReciterList() {
        logger.info("AudioBanner: reciters button tapped. State: \(playingState)")
        modalRequest = .present(
            reciterListBuilder.build(withListener: self, standalone: true),
            owner: "reciter_list",
            kind: "sheet"
        )
    }

    public func onSelectedReciterChanged(to reciter: Reciter) {
        logger.info("AudioBanner: onSelectedReciterChanged to \(reciter.id)")
        selectReciter(reciter)
        playingState = .stopped
    }
}

extension AudioBannerViewModel: AdvancedAudioOptionsListener {
    private var advancedAudioOptions: AdvancedAudioOptions? {
        guard let audioRange, let selectedReciter else {
            return nil
        }
        return AdvancedAudioOptions(
            reciter: selectedReciter,
            start: audioRange.start,
            end: audioRange.end,
            verseRuns: verseRuns,
            listRuns: listRuns,
            verseDelay: verseDelay,
            repetitionDelay: repetitionDelay
        )
    }

    func showAdvancedAudioOptions() {
        logger.info("AudioBanner: more button tapped. State: \(playingState)")
        if case .stopped = playingState {
            setAudioRangeForCurrentPage()
        }

        guard let options = advancedAudioOptions else {
            crashContext.setAdvancedAudioOptionsPhase("unavailable")
            logger.info("AudioBanner: showAdvancedAudioOptions couldn't construct advanced audio options")
            return
        }
        crashContext.setAdvancedAudioOptionsPhase("presentation_requested")
        modalRequest = .present(
            advancedAudioOptionsBuilder.build(withListener: self, options: options),
            owner: "advanced_audio_options",
            kind: "sheet"
        )
    }

    public func updateAudioOptions(to newOptions: AdvancedAudioOptions) {
        crashContext.setAdvancedAudioOptionsPhase("applying")
        logger.info("AudioBanner: playing advanced audio options \(newOptions)")
        selectReciter(newOptions.reciter)
        AudioPreferences.shared.verseDelay = newOptions.verseDelay
        AudioPreferences.shared.repetitionDelay = newOptions.repetitionDelay
        AudioPreferences.shared.verseRuns = newOptions.verseRuns
        AudioPreferences.shared.listRuns = newOptions.listRuns
        // Only a range played from here is remembered, so playing a page never replaces it.
        AudioPreferences.shared.saveLastPlaybackRange(LastPlaybackRange(
            start: newOptions.start,
            end: newOptions.end,
            verseRuns: newOptions.verseRuns,
            listRuns: newOptions.listRuns
        ))
        play(
            from: newOptions.start,
            to: newOptions.end,
            verseRuns: newOptions.verseRuns,
            listRuns: newOptions.listRuns,
            playbackRate: playbackRate,
            verseDelay: newOptions.verseDelay,
            repetitionDelay: newOptions.repetitionDelay
        )
        crashContext.setAdvancedAudioOptionsPhase("applied")
    }

    public func dismissAudioOptions() {
        logger.info("AudioBanner: dismiss advanced audio options")
        crashContext.setAdvancedAudioOptionsPhase("dismiss_requested")
        modalRequest = .dismiss(owner: "advanced_audio_options")
    }
}

private extension AnalyticsLibrary {
    func playFrom(menu: Bool) {
        logEvent("PlayAudioFrom", value: menu ? "Menu" : "AudioBar")
    }
}
