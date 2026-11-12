import XCTest
@testable import QuranViewFeature

final class ReaderBarActionsTests: XCTestCase {
    func test_iPhoneInPortrait_keepsBookmarkAndTranslationBesideTheOverflow() {
        XCTAssertEqual(ReaderBarActions.count(for: CGSize(width: 402, height: 874)), 2)
        XCTAssertEqual(ReaderBarActions.count(for: CGSize(width: 375, height: 667)), 2)
    }

    func test_iPhoneInLandscape_showsEveryAction() {
        XCTAssertEqual(ReaderBarActions.count(for: CGSize(width: 874, height: 402)), 4)
    }

    func test_smallIPhoneInLandscape_addsSearch() {
        XCTAssertEqual(ReaderBarActions.count(for: CGSize(width: 568, height: 320)), 3)
    }

    func test_iPad_showsEveryAction() {
        XCTAssertEqual(ReaderBarActions.count(for: CGSize(width: 820, height: 1180)), 4)
    }

    func test_narrowWindow_keepsOnlyTheBookmark() {
        XCTAssertEqual(ReaderBarActions.count(for: CGSize(width: 320, height: 1180)), 1)
    }
}
