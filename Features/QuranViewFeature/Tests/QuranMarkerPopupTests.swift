import QuranKit
import XCTest
@testable import QuranViewFeature

@MainActor
final class QuranMarkerPopupTests: XCTestCase {
    // MARK: Internal

    func testAJuzStartIsNamedAsTheJuz() {
        let juz2 = quran.juzs[1]
        XCTAssertEqual(QuranMarkerPopup.name(for: juz2.page), juz2.localizedName)
    }

    func testOtherQuarterStartsAreNamedAsTheQuarter() {
        let quarter = quran.quarters[1]
        XCTAssertEqual(QuranMarkerPopup.name(for: quarter.page), quarter.localizedName)
    }

    func testAPageThatStartsNoQuarterHasNoMarker() {
        let page = quran.pages.first { $0.quarter == nil }!
        XCTAssertNil(QuranMarkerPopup.name(for: page))
    }

    func testThePagesTheReaderOpensOnShowNothing() {
        var popup = QuranMarkerPopup(now: { self.now })
        XCTAssertNil(popup.marker(forVisiblePages: [quran.juzs[1].page]))
    }

    func testTurningToAQuarterStartShowsItsName() {
        var popup = QuranMarkerPopup(now: { self.now })
        let target = quran.juzs[1].page
        _ = popup.marker(forVisiblePages: [target.previous!])
        XCTAssertEqual(popup.marker(forVisiblePages: [target]), quran.juzs[1].localizedName)
    }

    func testAtMostOnePopupEveryThreeSeconds() {
        var popup = QuranMarkerPopup(now: { self.now })
        let pages = quran.quarters[1 ... 3].map(\.page)
        _ = popup.marker(forVisiblePages: [pages[0].previous!])
        XCTAssertNotNil(popup.marker(forVisiblePages: [pages[0]]))

        now.addTimeInterval(2)
        XCTAssertNil(popup.marker(forVisiblePages: [pages[1]]))

        now.addTimeInterval(1)
        XCTAssertNotNil(popup.marker(forVisiblePages: [pages[2]]))
    }

    func testTwoPagesShowTheFirstMarker() {
        var popup = QuranMarkerPopup(now: { self.now })
        let quarter = quran.quarters[1]
        let pages = [quarter.page, quarter.page.next!]
        _ = popup.marker(forVisiblePages: [quarter.page.previous!])
        XCTAssertEqual(popup.marker(forVisiblePages: pages.reversed()), quarter.localizedName)
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405
    private var now = Date(timeIntervalSince1970: 0)
}
