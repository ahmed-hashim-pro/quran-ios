import QuranAudio
import XCTest
@testable import NoorUI

final class AudioRepeatButtonTests: XCTestCase {
    func test_badge_showsNothingForASinglePlay() {
        XCTAssertNil(AudioRepeatButton.badge(for: .finite(1)))
    }

    func test_badge_countsTheRepeatsAfterTheFirstPlayAsAndroidDoes() {
        XCTAssertEqual(AudioRepeatButton.badge(for: .finite(2)), "1")
        XCTAssertEqual(AudioRepeatButton.badge(for: .finite(4)), "3")
        XCTAssertEqual(AudioRepeatButton.badge(for: .finite(10)), "9")
    }

    func test_badge_showsInfinityForALoop() {
        XCTAssertEqual(AudioRepeatButton.badge(for: .indefinite), "∞")
    }
}
