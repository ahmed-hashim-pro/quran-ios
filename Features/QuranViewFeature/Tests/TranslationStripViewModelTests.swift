import Localization
import QuranText
import QuranTextKit
import XCTest
@testable import QuranViewFeature

@MainActor
final class TranslationStripViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        savedFontSize = UserDefaults.standard.object(forKey: fontSizeKey)
    }

    override func tearDown() {
        UserDefaults.standard.set(savedFontSize, forKey: fontSizeKey)
        super.tearDown()
    }

    func test_sourceName_namesTheFirstTranslationAndCountsTheOthers() {
        XCTAssertEqual(TranslationStripViewModel.sourceName(["Sahih International"]), "Sahih International")
        XCTAssertEqual(
            TranslationStripViewModel.sourceName(["Sahih International", "Yusuf Ali", "Pickthall"]),
            "Sahih International  +\(NumberFormatter.shared.format(2))"
        )
    }

    func test_sourceName_withNoTranslation_offersToShowOne() {
        XCTAssertEqual(TranslationStripViewModel.sourceName([]), lAndroid("menu_translation"))
    }

    func test_increasingTheFontSize_savesTheNextLargerSize() {
        FontSizePreferences.shared.translationFontSize = .medium
        let sut = makeSut()

        sut.increaseFontSize()

        XCTAssertEqual(FontSizePreferences.shared.translationFontSize, .large)
        XCTAssertEqual(sut.fontSize, .large)
    }

    func test_decreasingTheFontSize_savesTheNextSmallerSize() {
        FontSizePreferences.shared.translationFontSize = .medium
        let sut = makeSut()

        sut.decreaseFontSize()

        XCTAssertEqual(FontSizePreferences.shared.translationFontSize, .small)
    }

    func test_fontSizeStopsAtTheEnds() {
        FontSizePreferences.shared.translationFontSize = .xSmall
        XCTAssertFalse(makeSut().canDecreaseFontSize)

        FontSizePreferences.shared.translationFontSize = .accessibility5
        XCTAssertFalse(makeSut().canIncreaseFontSize)
    }

    func test_tappingTheSource_opensTheTranslations() {
        var opened = 0
        let sut = TranslationStripViewModel(localTranslationsRetriever: nil) { opened += 1 }

        sut.openTranslations()

        XCTAssertEqual(opened, 1)
    }

    // MARK: Private

    private let fontSizeKey = "translationFontSize"
    private var savedFontSize: Any?

    private func makeSut() -> TranslationStripViewModel {
        TranslationStripViewModel(localTranslationsRetriever: nil) {}
    }
}
