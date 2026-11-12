import QuranAudio
import XCTest
@testable import AudioBannerFeature

final class AudioBarRepeatTests: XCTestCase {
    func test_cyclesAndroidsAudioBarRepeats() {
        var runs = Runs.finite(1)
        var cycle: [Runs] = []
        for _ in 0 ..< 6 {
            runs = runs.nextAudioBarRepeat
            cycle.append(runs)
        }
        XCTAssertEqual(cycle, [.finite(2), .finite(3), .finite(4), .indefinite, .finite(1), .finite(2)])
    }

    func test_aCountBeyondTheCycleStartsItAgain() {
        XCTAssertEqual(Runs.finite(5).nextAudioBarRepeat, .finite(1))
        XCTAssertEqual(Runs.finite(100).nextAudioBarRepeat, .finite(1))
    }
}
