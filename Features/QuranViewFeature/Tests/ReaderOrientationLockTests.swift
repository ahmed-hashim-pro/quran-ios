import UIKit
import XCTest
@testable import QuranViewFeature

final class ReaderOrientationLockTests: XCTestCase {
    func testUnlockedFollowsTheDevice() {
        XCTAssertNil(ReaderOrientationLock.supportedOrientations(locked: false, landscape: false, idiom: .phone))
        XCTAssertNil(ReaderOrientationLock.supportedOrientations(locked: false, landscape: true, idiom: .phone))
    }

    func testLockedKeepsPortrait() {
        XCTAssertEqual(ReaderOrientationLock.supportedOrientations(locked: true, landscape: false, idiom: .phone), .portrait)
    }

    func testLockedWithLandscapeKeepsLandscape() {
        XCTAssertEqual(ReaderOrientationLock.supportedOrientations(locked: true, landscape: true, idiom: .phone), .landscape)
    }

    func testIPadFollowsTheDeviceEvenWhenLocked() {
        XCTAssertNil(ReaderOrientationLock.supportedOrientations(locked: true, landscape: true, idiom: .pad))
        XCTAssertFalse(ReaderOrientationLock.isAvailable(on: .pad))
        XCTAssertTrue(ReaderOrientationLock.isAvailable(on: .phone))
    }
}
