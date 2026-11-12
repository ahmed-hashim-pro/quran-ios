import XCTest
@testable import MoreMenuFeature

@MainActor
final class MoreMenuViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        saved = keys.map { UserDefaults.standard.object(forKey: $0) }
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    override func tearDown() {
        for (key, value) in zip(keys, saved) {
            UserDefaults.standard.set(value, forKey: key)
        }
        super.tearDown()
    }

    func testOrientationLockStartsOff() {
        let sut = makeSut()

        XCTAssertFalse(sut.orientationLocked)
        XCTAssertFalse(sut.landscapeOrientation)
    }

    func testOrientationLockIsSavedUnderAndroidsKeys() {
        let sut = makeSut()

        sut.orientationLocked = true
        sut.landscapeOrientation = true

        XCTAssertTrue(UserDefaults.standard.bool(forKey: "lockOrientation"))
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "landscapeOrientation"))
        XCTAssertTrue(makeSut().orientationLocked)
    }

    // MARK: Private

    private let keys = ["lockOrientation", "landscapeOrientation"]
    private var saved: [Any?] = []

    private func makeSut() -> MoreMenuViewModel {
        MoreMenuViewModel(model: MoreMenuModel(isWordPointerActive: false, state: MoreMenuControlsState()))
    }
}
