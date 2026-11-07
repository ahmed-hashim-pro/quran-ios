import UIKit
import XCTest
@testable import NoorUI

final class NightBrightnessTests: XCTestCase {
    func testDefaultsLeaveColorsAlone() {
        let brightness = NightBrightness.default
        XCTAssertEqual(brightness.textLevel, 1)
        XCTAssertEqual(brightness.adjustBackground(.black), .black)
        XCTAssertEqual(brightness.adjustText(.white), .white)
    }

    func testValuesAreClampedToAndroidRanges() {
        let brightness = NightBrightness(text: 300, background: 100)
        XCTAssertEqual(brightness.text, 255)
        XCTAssertEqual(brightness.background, 64)
        XCTAssertEqual(NightBrightness(text: -4, background: -1), NightBrightness(text: 0, background: 0))
    }

    func testBackgroundOnBlackMatchesAndroidGray() throws {
        let color = NightBrightness(text: 255, background: 51).adjustBackground(.black)
        let level = try XCTUnwrap(color.grayLevel)
        XCTAssertEqual(level, 51 / 255, accuracy: 0.001)
    }

    func testTextIsLiftedWithTheBackgroundLikeAndroid() {
        // Android: min(255, 50 * ln(1 + background) + text).
        let brightness = NightBrightness(text: 100, background: 20)
        XCTAssertEqual(brightness.textLevel, (50 * log1p(20) + 100) / 255, accuracy: 0.0001)
        XCTAssertEqual(NightBrightness(text: 250, background: 64).textLevel, 1)
    }

    func testTextDimsTheThemeTextColor() throws {
        let color = NightBrightness(text: 128, background: 0).adjustText(.white)
        let level = try XCTUnwrap(color.grayLevel)
        XCTAssertEqual(level, 128 / 255, accuracy: 0.001)
    }
}

private extension UIColor {
    var grayLevel: CGFloat? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha), red == green, green == blue else { return nil }
        return red
    }
}
