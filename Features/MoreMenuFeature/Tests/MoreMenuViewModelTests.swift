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

    func testFocusModeStartsFromTheReader() {
        let sut = MoreMenuViewModel(model: MoreMenuModel(isWordPointerActive: false, isFocusModeActive: true, state: MoreMenuControlsState()))

        XCTAssertTrue(sut.focusModeEnabled)
    }

    func testTurningFocusModeOnTellsTheReader() {
        let listener = MoreMenuListenerSpy()
        let sut = makeSut()
        sut.listener = listener

        sut.focusModeEnabled = true

        XCTAssertEqual(listener.focusModeUpdates, [true])
    }

    func testAdvancedOptionsTellsTheReader() {
        let listener = MoreMenuListenerSpy()
        let sut = makeSut()
        sut.listener = listener

        sut.openAdvancedOptions()

        XCTAssertEqual(listener.advancedOptionsTaps, 1)
    }

    // MARK: Private

    private let keys = ["lockOrientation", "landscapeOrientation"]
    private var saved: [Any?] = []

    private func makeSut() -> MoreMenuViewModel {
        MoreMenuViewModel(model: MoreMenuModel(isWordPointerActive: false, state: MoreMenuControlsState()))
    }
}

@MainActor
private final class MoreMenuListenerSpy: MoreMenuListener {
    private(set) var focusModeUpdates: [Bool] = []
    private(set) var advancedOptionsTaps = 0

    func onTranslationsSelectionsTapped() {}
    func onIsWordPointerActiveUpdated(to isWordPointerActive: Bool) {}

    func onFocusModeUpdated(to isFocusModeActive: Bool) {
        focusModeUpdates.append(isFocusModeActive)
    }

    func onAdvancedOptionsTapped() {
        advancedOptionsTaps += 1
    }
}
