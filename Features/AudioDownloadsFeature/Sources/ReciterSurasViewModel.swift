//
//  ReciterSurasViewModel.swift
//  QuranEngine
//

import BatchDownloader
import Combine
import Foundation
import QuranAudio
import QuranAudioKit
import QuranKit
import ReciterService
import SwiftUI
import SystemDependencies
import UIx
import Utilities
import VLogging

struct ReciterSuraItem: Identifiable, Equatable {
    enum State: Equatable {
        case notDownloaded
        case downloading(Double)
        case downloaded
    }

    let sura: Sura
    let state: State

    var id: Int { sura.suraNumber }
}

/// Downloads, cancels and deletes one reciter's audio a surah at a time.
@MainActor
final class ReciterSurasViewModel: ObservableObject {
    // MARK: Lifecycle

    init(files: SuraAudioFiles, quran: Quran, downloader: QuranAudioDownloader, fileSystem: FileSystem) {
        self.files = files
        self.quran = quran
        self.downloader = downloader
        self.fileSystem = fileSystem
    }

    // MARK: Internal

    @Published var error: Error?
    @Published var editMode: EditMode = .inactive
    @Published private(set) var downloaded: Set<Sura> = []
    @Published private(set) var progress: [Sura: Double] = [:]

    var reciter: Reciter { files.reciter }

    var items: [ReciterSuraItem] {
        quran.suras.map { sura in
            if let value = progress[sura] {
                return ReciterSuraItem(sura: sura, state: .downloading(value))
            }
            return ReciterSuraItem(sura: sura, state: downloaded.contains(sura) ? .downloaded : .notDownloaded)
        }
    }

    func start() async {
        downloaded = files.downloadedSuras(in: quran)
        await downloadsObserver.observe(Set(await downloader.runningAudioDownloads()))
        for await newValue in downloadsObserver.progressPublisher.values() {
            // A surah that stops downloading has finished or failed, so look at its files again.
            for sura in Set(progress.keys).subtracting(newValue.keys) where files.isDownloaded(sura) {
                downloaded.insert(sura)
            }
            progress = newValue
        }
    }

    func download(_ sura: Sura) async {
        logger.info("Downloads: downloading sura \(sura.suraNumber) of reciter \(reciter.id)")
        progress[sura] = 0
        do {
            let response = try await downloader.download(from: sura.firstVerse, to: sura.lastVerse, reciter: reciter)
            await downloadsObserver.observe([response])
        } catch {
            progress.removeValue(forKey: sura)
            self.error = error
        }
    }

    func cancel(_ sura: Sura) async {
        logger.info("Downloads: cancel sura \(sura.suraNumber) of reciter \(reciter.id)")
        let running = downloadsObserver.runningDownloads.first { files.sura(of: $0, in: quran) == sura }
        await running?.cancel()
    }

    func delete(_ sura: Sura) -> AsyncAction? {
        guard downloaded.contains(sura) else {
            return nil
        }
        return { [weak self] in
            guard let self else { return }
            logger.info("Downloads: deleting sura \(sura.suraNumber) of reciter \(reciter.id)")
            do {
                for file in files.deletableFiles(of: sura) where fileSystem.fileExists(at: file.url) {
                    try fileSystem.removeItem(at: file.url)
                }
                downloaded.remove(sura)
            } catch {
                self.error = error
            }
        }
    }

    // MARK: Private

    private let files: SuraAudioFiles
    private let quran: Quran
    private let downloader: QuranAudioDownloader
    private let fileSystem: FileSystem
    private lazy var downloadsObserver = DownloadsObserver<Sura>(
        extractKey: { [files, quran] in files.sura(of: $0, in: quran) },
        showError: { [weak self] in self?.error = $0 }
    )
}
