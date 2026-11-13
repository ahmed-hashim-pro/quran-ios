import NoorUI
import XCTest
@testable import QuranViewFeature

@MainActor
final class ReadingModeTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        savedStyle = theme.themeStyle
        savedAppearance = theme.appearanceMode
        savedDefaults = keys.map { UserDefaults.standard.object(forKey: $0) }
    }

    override func tearDown() {
        // Through the service first, so the windows take their style back too.
        theme.themeStyle = savedStyle
        theme.appearanceMode = savedAppearance
        for (key, value) in zip(keys, savedDefaults) {
            if let value {
                UserDefaults.standard.set(value, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        super.tearDown()
    }

    // MARK: Shown

    func test_aDarkReaderIsNightWhateverItsStyle() {
        for style in [ThemeStyle.original, .paper, .calm, .focus, .quiet] {
            XCTAssertEqual(ReadingMode(themeStyle: style, isDark: true), .night, "\(style)")
        }
    }

    func test_theQuietStyleIsNightInLightModeToo() {
        XCTAssertEqual(ReadingMode(themeStyle: .quiet, isDark: false), .night)
    }

    func test_aLightReaderIsSepiaOnTheWarmPageAndDayOnAnyOtherStyle() {
        XCTAssertEqual(ReadingMode(themeStyle: .calm, isDark: false), .sepia)
        for style in [ThemeStyle.original, .paper, .focus] {
            XCTAssertEqual(ReadingMode(themeStyle: style, isDark: false), .day, "\(style)")
        }
    }

    func test_aFreshInstallInLightModeShowsDay() {
        removeSavedTheme()

        XCTAssertEqual(ReadingMode(themeStyle: theme.themeStyle, isDark: theme.userInterfaceStyle == .dark), .day)
    }

    // MARK: Chosen

    func test_dayTurnsTheReaderLightOnTheOriginalPage() {
        theme.themeStyle = .quiet
        theme.appearanceMode = .dark

        ReadingMode.day.apply(to: theme)

        XCTAssertEqual(theme.themeStyle, .original)
        XCTAssertEqual(theme.appearanceMode, .light)
    }

    func test_sepiaTurnsTheReaderLightOnTheWarmPage() {
        theme.themeStyle = .original
        theme.appearanceMode = .dark

        ReadingMode.sepia.apply(to: theme)

        XCTAssertEqual(theme.themeStyle, .calm)
        XCTAssertEqual(theme.appearanceMode, .light)
    }

    func test_nightTurnsTheReaderDarkAndClearsSepia() {
        theme.themeStyle = .calm
        theme.appearanceMode = .light

        ReadingMode.night.apply(to: theme)

        XCTAssertEqual(theme.themeStyle, .original)
        XCTAssertEqual(theme.appearanceMode, .dark)
    }

    func test_eachModeChosenIsTheModeShown() {
        for mode in ReadingMode.allCases {
            mode.apply(to: theme)

            XCTAssertEqual(ReadingMode(themeStyle: theme.themeStyle, isDark: theme.userInterfaceStyle == .dark), mode)
        }
    }

    // MARK: Bar

    func test_theBarFollowsAStyleChosenInTheThemeSettings() {
        theme.themeStyle = .original
        let sut = ReadingModeBarViewModel(themeService: theme)

        theme.themeStyle = .paper

        XCTAssertEqual(sut.themeStyle, .paper)
    }

    func test_choosingAModeOnTheBarSetsTheTheme() {
        theme.themeStyle = .original
        theme.appearanceMode = .light
        let sut = ReadingModeBarViewModel(themeService: theme)

        sut.select(.sepia)

        XCTAssertEqual(theme.themeStyle, .calm)
        XCTAssertEqual(sut.themeStyle, .calm)
    }

    // MARK: Private

    private let theme = ThemeService.shared
    private let keys = ["theme", "themeStyle"]
    private var savedDefaults: [Any?] = []
    private var savedStyle = ThemeStyle.paper
    private var savedAppearance = AppearanceMode.auto

    /// Back to the defaults through the service, then without the saved keys, as on a fresh install.
    private func removeSavedTheme() {
        theme.themeStyle = .paper
        theme.appearanceMode = .light
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
}
