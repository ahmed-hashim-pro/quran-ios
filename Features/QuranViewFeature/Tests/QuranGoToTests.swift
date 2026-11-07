import QuranKit
import XCTest
@testable import QuranViewFeature

final class QuranGoToTests: XCTestCase {
    // MARK: Internal

    func testReadsDigitsFromEveryKeyboard() {
        XCTAssertEqual(typedNumber("298"), 298)
        XCTAssertEqual(typedNumber("٢٩٨"), 298)
        XCTAssertEqual(typedNumber("۲۹۸"), 298)
        XCTAssertEqual(typedNumber(" 12 "), 12)
        XCTAssertNil(typedNumber(""))
        XCTAssertNil(typedNumber("12a"))
        XCTAssertNil(typedNumber("-3"))
    }

    func testStartsOnTheReadersPageAndSurah() {
        let form = QuranGoToForm(start: quran.pages[49])
        XCTAssertEqual(form.target, .page(quran.pages[49]))
        XCTAssertEqual(form.sura, quran.pages[49].startSura)
    }

    func testPagesAreLimitedToThePrint() {
        var form = QuranGoToForm(start: quran.pages[0])
        form.pageText = "604"
        XCTAssertEqual(form.target, .page(quran.pages[603]))
        form.pageText = "605"
        XCTAssertNil(form.target)
        XCTAssertTrue(form.isOutOfRange)
        XCTAssertEqual(form.limit, 604)
        form.pageText = ""
        XCTAssertFalse(form.isOutOfRange)
    }

    func testAyahsAreLimitedToTheSurah() {
        var form = QuranGoToForm(start: quran.pages[0])
        form.mode = .ayah
        form.sura = quran.suras[1]
        XCTAssertEqual(form.limit, 286)
        form.ayahText = "255"
        XCTAssertEqual(form.target, .ayah(AyahNumber(quran: quran, sura: 2, ayah: 255)!))
        form.ayahText = "287"
        XCTAssertTrue(form.isOutOfRange)
    }

    func testChoosingAnotherSurahStartsAtItsFirstAyah() {
        var form = QuranGoToForm(start: quran.pages[0])
        form.mode = .ayah
        form.ayahText = "5"
        form.sura = quran.suras[17]
        XCTAssertEqual(form.target, .ayah(quran.suras[17].firstVerse))
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405
}
