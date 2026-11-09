//
//  WordFrameLineRepairTests.swift
//
//  Part of the my-stream fork.
//

import QuranGeometry
import QuranKit
import XCTest
@testable import WordFrameService

final class WordFrameLineRepairTests: XCTestCase {
    private let quran = Quran.hafsMadani1405

    private func frame(_ ayah: Int, piece: Int, line: Int, _ minX: Int, _ maxX: Int, _ minY: Int, _ maxY: Int) -> WordFrame {
        WordFrame(line: line, word: Word(verse: AyahNumber(quran: quran, sura: 2, ayah: ayah)!, wordNumber: piece), minX: minX, maxX: maxX, minY: minY, maxY: maxY)
    }

    /// Page 2 of quran_android's Madinah Colored database, as it is stored: `line_number` counts the pieces of each verse.
    private var madinaColoredPage2: [WordFrame] {
        [
            frame(1, piece: 1, line: 1, 160, 856, 311, 400), frame(1, piece: 2, line: 2, 754, 931, 455, 556),
            frame(2, piece: 1, line: 1, 87, 754, 455, 556), frame(2, piece: 2, line: 2, 683, 932, 598, 700),
            frame(3, piece: 1, line: 1, 83, 683, 598, 700), frame(3, piece: 2, line: 2, 78, 934, 734, 835),
            frame(4, piece: 1, line: 1, 76, 928, 881, 986), frame(4, piece: 2, line: 2, 303, 925, 1029, 1139),
            frame(5, piece: 1, line: 1, 75, 303, 1029, 1139), frame(5, piece: 2, line: 2, 75, 929, 1176, 1281),
        ]
    }

    func testGivesPiecesTheLineTheySitOn() {
        let lines = WordFrameLineRepair().repaired(madinaColoredPage2).map(\.line)
        // basmala; ayah 1's end and ayah 2's start; then each line below.
        XCTAssertEqual(lines, [1, 2, 2, 3, 3, 4, 5, 6, 6, 7])
    }

    func testAVerseStaysWithinItsOwnLinesAfterProcessing() {
        let processed = WordFrameProcessor().processWordFrames(madinaColoredPage2)
        let ayah3 = AyahNumber(quran: quran, sura: 2, ayah: 3)!
        let rect = processed.wordFramesForVerse(ayah3).map(\.rect).reduce(CGRect.null) { $0.union($1) }
        // It was one block over most of the page before; its own two lines are 598 to 835.
        XCTAssertGreaterThan(rect.minY, 540)
        XCTAssertLessThan(rect.maxY, 880)
    }

    func testATapLandsOnTheVerseUnderIt() {
        let processed = WordFrameProcessor().processWordFrames(madinaColoredPage2)
        let scale = WordFrameScale(scale: 1, xOffset: 0, yOffset: 0)
        let ayah3 = AyahNumber(quran: quran, sura: 2, ayah: 3)!
        XCTAssertEqual(processed.wordAtLocation(CGPoint(x: 400, y: 650), imageScale: scale)?.verse, ayah3)
        XCTAssertEqual(processed.wordAtLocation(CGPoint(x: 500, y: 785), imageScale: scale)?.verse, ayah3)
        let ayah4 = AyahNumber(quran: quran, sura: 2, ayah: 4)!
        XCTAssertEqual(processed.wordAtLocation(CGPoint(x: 500, y: 930), imageScale: scale)?.verse, ayah4)
    }

    func testLeavesRealLineNumbersAlone() {
        let words = [
            frame(54, piece: 1, line: 1, 872, 956, 32, 94), frame(54, piece: 2, line: 1, 756, 867, 29, 94),
            frame(54, piece: 12, line: 2, 825, 956, 137, 213), frame(54, piece: 13, line: 2, 690, 819, 129, 196),
        ]
        XCTAssertEqual(WordFrameLineRepair().repaired(words), words)
    }

    func testAnEmptyPageIsFine() {
        XCTAssertEqual(WordFrameLineRepair().repaired([]), [])
    }
}
