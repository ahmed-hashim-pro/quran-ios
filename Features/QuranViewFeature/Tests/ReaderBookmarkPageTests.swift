import QuranKit
import XCTest
@testable import QuranViewFeature

final class ReaderBookmarkPageTests: XCTestCase {
    func test_twoPages_bookmarkTheSecondPageOfThePair() {
        XCTAssertEqual([quran.pages[2], quran.pages[3]].bookmarkPage, quran.pages[3])
    }

    func test_onePage_bookmarksIt() {
        XCTAssertEqual([quran.pages[4]].bookmarkPage, quran.pages[4])
    }

    func test_noPage_bookmarksNothing() {
        XCTAssertNil([Page]().bookmarkPage)
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405
}
