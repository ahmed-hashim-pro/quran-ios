import UIKit
import XCTest
@testable import QuranViewFeature

@MainActor
final class QuranViewReadingModeBarTests: XCTestCase {
    func test_floatsCenteredSixteenPointsAboveTheAudioBar() {
        let context = makeReader()

        XCTAssertEqual(context.bar.frame.maxY, context.audioView.frame.minY - 16)
        XCTAssertEqual(context.bar.frame.midX, context.sut.bounds.midX)
    }

    func test_hidesAndShowsWithTheBars() {
        let context = makeReader()

        context.sut.setBarsHidden(true)
        XCTAssertTrue(context.bar.isHidden)
        XCTAssertFalse(context.bar.isUserInteractionEnabled)

        context.sut.setBarsHidden(false)
        XCTAssertFalse(context.bar.isHidden)
        XCTAssertTrue(context.bar.isUserInteractionEnabled)
    }

    func test_animatedHidingEndsHiddenAtFullAlpha() {
        let context = makeReader()
        let animationCompleted = expectation(description: "Animation completed")

        context.sut.setBarsHidden(true, animated: true) {
            animationCompleted.fulfill()
        }
        wait(for: [animationCompleted], timeout: 1)

        XCTAssertTrue(context.bar.isHidden)
        XCTAssertEqual(context.bar.alpha, 1)
    }

    func test_addedWhileTheBarsAreHidden_staysHidden() {
        let sut = QuranView()
        sut.addAudioBannerView(UIView())
        sut.setBarsHidden(true)
        let bar = UIView()

        sut.addReadingModeBarView(bar)

        XCTAssertTrue(bar.isHidden)
    }

    func test_bottomBarsHeightReachesTheTopOfTheReadingModes() {
        let context = makeReader()

        XCTAssertEqual(context.sut.bottomBarsHeight, Self.audioBarHeight + 16 + Self.barHeight)
    }

    func test_followsANewAudioBar() {
        let context = makeReader()
        let newAudioView = UIView()
        newAudioView.heightAnchor.constraint(equalToConstant: 60).isActive = true

        context.sut.addAudioBannerView(newAudioView)
        context.retainedWindow.layoutIfNeeded()

        XCTAssertEqual(context.bar.frame.maxY, newAudioView.frame.minY - 16)
    }

    // MARK: Private

    private struct ReaderContext {
        let retainedWindow: UIWindow
        let sut: QuranView
        let audioView: UIView
        let bar: UIView
    }

    private static let audioBarHeight: CGFloat = 120
    private static let barHeight: CGFloat = 44

    private func makeReader() -> ReaderContext {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let sut = QuranView()
        sut.frame = window.bounds
        window.addSubview(sut)
        let audioView = UIView()
        audioView.heightAnchor.constraint(equalToConstant: Self.audioBarHeight).isActive = true
        sut.addAudioBannerView(audioView)
        let bar = UIView()
        NSLayoutConstraint.activate([
            bar.widthAnchor.constraint(equalToConstant: 200),
            bar.heightAnchor.constraint(equalToConstant: Self.barHeight),
        ])
        sut.addReadingModeBarView(bar)
        window.layoutIfNeeded()
        return ReaderContext(retainedWindow: window, sut: sut, audioView: audioView, bar: bar)
    }
}
