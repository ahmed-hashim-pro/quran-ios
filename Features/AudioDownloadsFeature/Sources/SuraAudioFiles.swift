//
//  SuraAudioFiles.swift
//  QuranEngine
//

import BatchDownloader
import Foundation
import QuranAudio
import QuranKit
import ReciterService
import Utilities

/// One reciter's audio, seen a surah at a time as quran_android's audio manager shows it.
struct SuraAudioFiles: Sendable {
    // MARK: Lifecycle

    init(reciter: Reciter, baseURL: URL, fileExists: @escaping @Sendable (URL) -> Bool) {
        self.reciter = reciter
        self.baseURL = baseURL
        self.fileExists = fileExists
    }

    // MARK: Internal

    let reciter: Reciter

    /// A surah counts as downloaded when every file of its own is on the phone, as `ReciterSizeInfoRetriever` counts them.
    func isDownloaded(_ sura: Sura) -> Bool {
        files(of: sura).allSatisfy { fileExists($0.url) }
    }

    func downloadedSuras(in quran: Quran) -> Set<Sura> {
        Set(quran.suras.filter(isDownloaded))
    }

    /// Never the gapless timing database or a gapped reciter's opening basmala, which other surahs use too.
    func deletableFiles(of sura: Sura) -> [RelativeFilePath] {
        guard case .gapped = reciter.audioType else {
            return files(of: sura)
        }
        let basmala = reciter.localURL(ayah: sura.quran.firstVerse)
        return files(of: sura).filter { $0 != basmala }
    }

    /// The surah a download is for, or nil when it is another reciter's or spans several surahs.
    func sura(of batch: DownloadBatchResponse, in quran: Quran) -> Sura? {
        sura(downloadingTo: batch.requests.map(\.destination), in: quran)
    }

    func sura(downloadingTo destinations: [RelativeFilePath], in quran: Quran) -> Sura? {
        let folder = reciter.localFolder()
        let numbers = Set(destinations
            .filter { $0.deletingLastPathComponent() == folder }
            .compactMap { Self.suraNumber(inFileNamed: $0.lastPathComponent) })
        // A gapped surah's download may carry the shared basmala, which is in Al-Fatihah.
        let own = numbers.subtracting([1])
        switch own.count {
        case 0: return numbers.isEmpty ? nil : quran.suras.first
        case 1: return own.first.flatMap { Sura(quran: quran, suraNumber: $0) }
        default: return nil
        }
    }

    // MARK: Private

    private let baseURL: URL
    private let fileExists: @Sendable (URL) -> Bool

    /// Audio files are named by surah, then ayah for gapped reciters: 002.mp3 or 002255.mp3.
    private static func suraNumber(inFileNamed name: String) -> Int? {
        let digits = name.prefix { $0.isASCII && $0.isNumber }
        guard digits.count == 3 || digits.count == 6 else {
            return nil
        }
        return Int(digits.prefix(3))
    }

    private func files(of sura: Sura) -> [RelativeFilePath] {
        reciter.audioFiles(baseURL: baseURL, from: sura.firstVerse, to: sura.lastVerse)
            .filter { $0.sura == sura }
            .map(\.local)
    }
}
