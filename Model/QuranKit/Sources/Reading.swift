//
//  Reading.swift
//
//
//  Created by Mohamed Afifi on 2023-02-14.
//

import Foundation

public enum Reading: Int {
    case hafs_1405 = 0
    case hafs_1440 = 1
    case tajweed = 2
    case hafs_1421 = 3
    case hafs_1441 = 4
    case hafs_1439 = 5
    case indoPak = 6
    // quran_android's prints, downloaded from its servers. Saved as a preference, so they sit far from upstream's numbers.
    case madinaColored = 101
    case newMadani = 102
    case naskh = 103
    case shemerly = 104
    case qaloon = 105
    case warsh = 106

    // MARK: Public

    public static let allReadings: [Reading] = [
        .hafs_1405, .tajweed, .hafs_1421, .hafs_1440, .hafs_1439, .hafs_1441, .indoPak,
    ]

    /// quran_android's eight prints, in its order.
    public static let androidReadings: [Reading] = [
        .madinaColored, .hafs_1405, .newMadani, .tajweed, .naskh, .shemerly, .qaloon, .warsh,
    ]

    public var quran: Quran {
        switch self {
        case .hafs_1405:
            return .hafsMadani1405
        case .hafs_1440:
            return .hafsMadani1440
        case .hafs_1421:
            return .hafsMadani1440
        case .hafs_1439:
            return .hafsMadani1440
        case .hafs_1441:
            return .hafsMadani1440
        case .tajweed:
            return .hafsMadani1405
        case .indoPak:
            return .hafsIndoPak
        case .madinaColored:
            return .hafsMadani1405
        case .newMadani:
            return .hafsNewMadani
        case .naskh:
            return .hafsNaskh
        case .shemerly:
            return .hafsShemerly
        case .qaloon, .warsh:
            return .qaloonWarsh
        }
    }

    /// Whether page assets need separately rendered ayah numbers and sura headers.
    public var drawsAyahNumbersAndSuraHeaders: Bool {
        switch self {
        case .hafs_1421, .hafs_1439, .hafs_1441:
            true
        case .hafs_1405, .hafs_1440, .tajweed, .indoPak:
            false
        case .madinaColored, .newMadani, .naskh, .shemerly, .qaloon, .warsh:
            false
        }
    }

    public var usesLinePages: Bool {
        linePageMetrics != nil
    }

    public var linePageMetrics: LinePageMetrics? {
        switch self {
        case .hafs_1439:
            return .madaniLinePages(widthParameter: 1080)
        case .hafs_1441:
            return .madaniLinePages(widthParameter: 1440)
        case .indoPak:
            return .indoPakLinePages
        case .hafs_1405, .hafs_1421, .hafs_1440, .tajweed:
            return nil
        case .madinaColored, .newMadani, .naskh, .shemerly, .qaloon, .warsh:
            return nil
        }
    }

    public var imageAssetWidth: Int {
        switch self {
        case .hafs_1405:
            return 1920
        case .hafs_1421:
            return 1120
        case .hafs_1440:
            return 1352
        case .hafs_1439:
            return 1080
        case .hafs_1441:
            return 1440
        case .tajweed:
            return 1280
        case .indoPak:
            return 1342
        case .madinaColored:
            return 1000
        case .newMadani, .qaloon, .warsh:
            return 1260
        case .naskh:
            return 1280
        case .shemerly:
            return 1200
        }
    }

    public var usesLinePageDividers: Bool {
        self == .indoPak
    }

    public var usesLinePageSidelines: Bool {
        self == .indoPak
    }

    public var usesInvertedQuranImageRenderingInDarkMode: Bool {
        switch self {
        case .hafs_1440, .hafs_1439, .hafs_1441, .tajweed, .indoPak:
            return true
        case .hafs_1405, .hafs_1421:
            return false
        case .madinaColored, .newMadani, .qaloon, .warsh:
            return true
        case .naskh, .shemerly:
            return false
        }
    }

    public var supportsWordPositions: Bool {
        switch self {
        case .hafs_1405:
            return true
        case .hafs_1421:
            return false
        case .hafs_1440:
            return false
        case .hafs_1439:
            return false
        case .hafs_1441:
            return false
        case .tajweed:
            // TODO: Enable word-by-word translation.
            // Tajweed ayah info contains words dimensions, but they don't match the word-by-word database.
            return false
        case .indoPak:
            return false
        case .madinaColored, .newMadani, .naskh, .shemerly, .qaloon, .warsh:
            return false
        }
    }

    public func ayahInfoDatabase(in directory: URL) -> URL {
        let width = imageAssetWidth
        return directory
            .appendingPathComponent("images_\(width)")
            .appendingPathComponent("databases")
            .appendingPathComponent("ayahinfo_\(width).db")
    }

    public func imagesDirectory(in directory: URL) -> URL {
        let width = imageAssetWidth
        return directory
            .appendingPathComponent("images_\(width)")
            .appendingPathComponent("width_\(width)")
    }
}
