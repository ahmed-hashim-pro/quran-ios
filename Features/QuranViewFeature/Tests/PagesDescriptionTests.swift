//
//  PagesDescriptionTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-14.
//

import Localization
import QuranKit
import XCTest
@testable import QuranViewFeature

final class PagesDescriptionTests: XCTestCase {
    // MARK: Internal

    func testOnePage() {
        XCTAssertEqual([quran.pages[1]].localizedDescription(language: .english), "Page 2, Juz' 1")
    }

    func testTwoPagesShowARange() {
        let pages = [quran.pages[1], quran.pages[2]]

        XCTAssertEqual(pages.localizedDescription(language: .english), "Pages 2–3, Juz' 1")
        XCTAssertEqual(
            withoutBidiIsolates(pages.localizedDescription(language: .arabic)),
            "صفحات 2–3، جزء 1"
        )
        XCTAssertEqual(pages.localizedDescription(language: .chinese), "第1卷，第2至3页")
    }

    func testTwoPagesAcrossJuzsShowTheFirstJuz() {
        let pages = [quran.pages[20], quran.pages[21]]

        XCTAssertEqual(pages.localizedDescription(language: .english), "Pages 21–22, Juz' 1")
    }

    func testThePrintNameFollowsThePages() {
        let page = [quran.pages[1]]

        XCTAssertEqual(
            page.localizedDescription(printName: Reading.warsh.printName(language: .english), language: .english),
            "Page 2, Juz' 1 · Warsh"
        )
        XCTAssertEqual(
            withoutBidiIsolates(page.localizedDescription(printName: Reading.warsh.printName(language: .arabic), language: .arabic)),
            "صفحة 2، جزء 1، ورش"
        )
    }

    /// Foundation isolates each argument, so without a leading mark the line has no strong letter and lays out left to right.
    func testTheArabicLineStartsRightToLeft() {
        let page = [quran.pages[1]]
        let text = page.localizedDescription(printName: Reading.warsh.printName(language: .arabic), language: .arabic)
        XCTAssertEqual(text.first, "\u{200F}")
    }

    func testEveryAndroidPrintHasANameInEnglishAndArabic() {
        for reading in Reading.androidReadings {
            for language in [Language.english, .arabic] {
                let name = reading.printName(language: language)
                XCTAssertNotNil(name, "\(reading) in \(language)")
                XCTAssertFalse(name?.hasPrefix("reading.") ?? true, "\(reading) in \(language) has no string")
            }
        }
        XCTAssertEqual(Set(Reading.androidReadings.compactMap { $0.printName(language: .english) }).count, Reading.androidReadings.count)
    }

    func testPrintsAndroidLacksHaveNoName() {
        XCTAssertNil(Reading.hafs_1440.printName())
        XCTAssertNil(Reading.indoPak.printName())
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405

    /// Foundation wraps `%@` arguments of a right-to-left format in bidi isolates, U+2066 to U+2069.
    private func withoutBidiIsolates(_ text: String) -> String {
        text.filter { !("\u{2066}" ... "\u{2069}").contains($0) && $0 != "\u{200F}" }
    }
}
