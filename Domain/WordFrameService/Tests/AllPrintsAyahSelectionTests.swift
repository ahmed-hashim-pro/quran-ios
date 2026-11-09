//
//  AllPrintsAyahSelectionTests.swift
//
//  Part of the my-stream fork.
//

import CoreGraphics
import QuranGeometry
import QuranKit
import WordFramePersistence
import XCTest
@testable import WordFrameService

/// Reads each print's real ayah info database, as the reader does, and checks that after processing a tap on any box
/// returns that box's verse. How far a verse's area grows is only reported: the processor stretches the ends of short
/// lines to the line's edges on purpose, as it does for the classic print. Skipped without PRINTS_DIR, a folder
/// laid out like the app's `readings` folder, because the pages are downloaded and not part of this repository.
/// PRINTS_CLASSIC points at the classic Madani print's folder, which ships in the app.
final class AllPrintsAyahSelectionTests: XCTestCase {
    private static let prints: [(name: String, reading: Reading, folder: String, width: Int)] = [
        ("madina_colored", .madinaColored, "madina_colored", 1000),
        ("new_madani", .newMadani, "new_madani", 1260),
        ("tajweed", .tajweed, "tajweed", 1280),
        ("naskh", .naskh, "shl_naskh", 1280),
        ("shemerly", .shemerly, "shemerly", 1200),
        ("qaloon", .qaloon, "qaloon", 1260),
        ("warsh", .warsh, "warsh", 1260),
    ]

    func testEveryPrintSelectsTheAyahUnderTheFinger() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let root = env["PRINTS_DIR"] else { throw XCTSkip("PRINTS_DIR is not set") }
        var databases = Self.prints.map { ($0.name, $0.reading, "\(root)/\($0.folder)/images_\($0.width)/databases/ayahinfo_\($0.width).db") }
        if let classic = env["PRINTS_CLASSIC"] {
            databases.append(("hafs_1405", .hafs_1405, "\(classic)/images_1920/databases/ayahinfo_1920.db"))
        }
        var report = ""
        for (name, reading, path) in databases {
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), "\(name) database at \(path)")
            let persistence = GRDBWordFramePersistence(fileURL: URL(fileURLWithPath: path))
            var misses = 0, wide = 0, boxes = 0, pages = 0
            defer { XCTAssertEqual(misses, 0, "\(name): taps on the wrong verse") }
            var badPages: [Int] = []
            var samples: [String] = []
            for page in reading.quran.pages {
                let raw = try await persistence.wordFrameCollectionForPage(page)
                guard !raw.isEmpty else { continue }
                pages += 1
                let processed = WordFrameProcessor().processWordFrames(raw)
                let pitch = raw.map { CGFloat($0.maxY - $0.minY) }.sorted()[raw.count / 2]
                var pageBad = false
                let scale = WordFrameScale(scale: 1, xOffset: 0, yOffset: 0)
                for frame in raw {
                    boxes += 1
                    let centre = CGPoint(x: frame.rect.midX, y: frame.rect.midY)
                    // Boxes that legitimately overlap another verse's box are not a miss.
                    let overlapped = raw.contains { $0.word.verse != frame.word.verse && $0.rect.contains(centre) }
                    if !overlapped, processed.wordAtLocation(centre, imageScale: scale)?.verse != frame.word.verse {
                        misses += 1
                        pageBad = true
                    }
                }
                for verse in Set(raw.map(\.word.verse)) {
                    let before = raw.filter { $0.word.verse == verse }.map(\.rect).reduce(CGRect.null) { $0.union($1) }
                    let after = processed.wordFramesForVerse(verse).map(\.rect).reduce(CGRect.null) { $0.union($1) }
                    if !before.insetBy(dx: -pitch * 1.5, dy: -pitch * 1.5).contains(after) {
                        wide += 1
                        pageBad = true
                        if samples.count < 6 {
                            let grow = (left: before.minX - after.minX, right: after.maxX - before.maxX, up: before.minY - after.minY, down: after.maxY - before.maxY)
                            samples.append("p\(page.pageNumber) \(verse.sura.suraNumber):\(verse.ayah) pitch \(Int(pitch)) grew L\(Int(grow.left)) R\(Int(grow.right)) U\(Int(grow.up)) D\(Int(grow.down))")
                        }
                    }
                }
                if pageBad { badPages.append(page.pageNumber) }
            }
            report += "\(name): \(pages) pages, \(boxes) boxes, \(misses) taps on the wrong verse, \(wide) verses that grew, pages \(badPages.prefix(12))\n    \(samples.joined(separator: "\n    "))\n"
        }
        print("ALLPRINTS\n" + report)
        XCTAssertFalse(report.isEmpty, "no data read")
    }
}
