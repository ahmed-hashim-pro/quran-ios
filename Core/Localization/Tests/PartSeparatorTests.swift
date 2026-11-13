import Foundation
import XCTest
@testable import Localization

final class PartSeparatorTests: XCTestCase {
    func testArabicScriptLanguagesSeparateWithTheArabicComma() {
        for identifier in ["ar", "ar_EG", "ar_SA@numbers=latn", "fa", "fa_IR", "ur", "ur_PK"] {
            XCTAssertEqual(Locale(identifier: identifier).partSeparator, "، ", identifier)
        }
    }

    func testOtherLanguagesSeparateWithAMiddleDot() {
        for identifier in ["en", "en_US", "fr", "tr", "zh-Hans"] {
            XCTAssertEqual(Locale(identifier: identifier).partSeparator, " · ", identifier)
        }
    }
}
