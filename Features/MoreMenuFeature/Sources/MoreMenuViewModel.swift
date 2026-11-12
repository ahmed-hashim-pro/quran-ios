//
//  MoreMenuViewModel.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/1/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Combine
import NoorUI
import QuranText
import QuranTextKit
import VLogging
import WordTextService

@MainActor
public protocol MoreMenuListener: AnyObject {
    func onTranslationsSelectionsTapped()
    func onIsWordPointerActiveUpdated(to isWordPointerActive: Bool)
    func onGoToTapped()
    func onAudioManagerTapped()
    func onSearchTapped()
    func onMushafPrintTapped()
}

extension MoreMenuListener {
    /// Only menus that turn on `MoreMenuControlsState.goTo` show the row.
    public func onGoToTapped() {}
    /// Only menus that turn on `MoreMenuControlsState.audioManager` show the row.
    public func onAudioManagerTapped() {}
    /// Only menus that turn on `MoreMenuControlsState.search` show the row.
    public func onSearchTapped() {}
    /// Only menus that turn on `MoreMenuControlsState.mushafPrint` show the row.
    public func onMushafPrintTapped() {}
}

@MainActor
final class MoreMenuViewModel: ObservableObject {
    // MARK: Lifecycle

    init(model: MoreMenuModel) {
        self.model = model
        state = model.state

        mode = preferences.quranMode
        wordPointerEnabled = model.isWordPointerActive
        wordPointerType = wordTextPreferences.wordTextType
        translationFontSize = fontSizePreferences.translationFontSize
        arabicFontSize = fontSizePreferences.arabicFontSize
        twoPagesEnabled = preferences.twoPagesEnabled
        splitPageAndTranslation = preferences.splitPageAndTranslation
        verticalScrollingEnabled = preferences.verticalScrollingEnabled
        markerPopupsEnabled = preferences.displayMarkerPopup
        pageInfoEnabled = themeService.showsPageInfo
        orientationLocked = preferences.lockOrientation
        landscapeOrientation = preferences.landscapeOrientation
        showLinePageDividers = preferences.showLinePageDividers
        showLinePageSidelines = preferences.showLinePageSidelines
        showArabicText = preferences.showArabicInTranslation
        #if QURAN_SYNC
        indicatorVisibility = preferences.ayahIndicatorVisibility
        #endif
        appearanceMode = themeService.appearanceMode

        state.twoPages = (model.state.twoPages == .conditional && TwoPagesUtils.hasEnoughHorizontalSpace()) ? .conditional : .alwaysOff
        if state.twoPages == .alwaysOff {
            state.splitPageAndTranslation = .alwaysOff
        }

        $mode
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set quran model \(newValue)")
                self?.preferences.quranMode = newValue
            }
            .store(in: &cancellables)

        $wordPointerEnabled
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set is word pointer active \(newValue)")
                self?.listener?.onIsWordPointerActiveUpdated(to: newValue)
            }
            .store(in: &cancellables)

        $wordPointerType
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set word pointer type \(newValue)")
                self?.wordTextPreferences.wordTextType = newValue
            }
            .store(in: &cancellables)

        $translationFontSize
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set translation font size \(newValue)")
                self?.fontSizePreferences.translationFontSize = newValue
            }
            .store(in: &cancellables)

        $arabicFontSize
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set arabic font size \(newValue)")
                self?.fontSizePreferences.arabicFontSize = newValue
            }
            .store(in: &cancellables)

        $twoPagesEnabled
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set two pages enabled \(newValue)")
                self?.preferences.twoPagesEnabled = newValue
            }
            .store(in: &cancellables)

        $splitPageAndTranslation
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set page beside translation \(newValue)")
                self?.preferences.splitPageAndTranslation = newValue
            }
            .store(in: &cancellables)

        $verticalScrollingEnabled
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set vertical scrolling enabled \(newValue)")
                self?.preferences.verticalScrollingEnabled = newValue
            }
            .store(in: &cancellables)

        $pageInfoEnabled
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set page info visible \(newValue)")
                self?.themeService.showsPageInfo = newValue
            }
            .store(in: &cancellables)

        $orientationLocked
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set orientation locked \(newValue)")
                self?.preferences.lockOrientation = newValue
            }
            .store(in: &cancellables)

        $landscapeOrientation
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set landscape orientation \(newValue)")
                self?.preferences.landscapeOrientation = newValue
            }
            .store(in: &cancellables)

        $markerPopupsEnabled
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set marker popups enabled \(newValue)")
                self?.preferences.displayMarkerPopup = newValue
            }
            .store(in: &cancellables)

        $showLinePageDividers
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set line page dividers visible \(newValue)")
                self?.preferences.showLinePageDividers = newValue
            }
            .store(in: &cancellables)

        $showLinePageSidelines
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set line page sidelines visible \(newValue)")
                self?.preferences.showLinePageSidelines = newValue
            }
            .store(in: &cancellables)

        $showArabicText
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set arabic text in translation visible \(newValue)")
                self?.preferences.showArabicInTranslation = newValue
            }
            .store(in: &cancellables)

        #if QURAN_SYNC
        $indicatorVisibility
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set ayah indicator visibility \(newValue)")
                self?.preferences.ayahIndicatorVisibility = newValue
            }
            .store(in: &cancellables)
        #endif

        $appearanceMode
            .dropFirst()
            .sink { [weak self] newValue in
                logger.info("More Menu: set appearanceMode \(newValue)")
                self?.themeService.appearanceMode = newValue
            }
            .store(in: &cancellables)
    }

    // MARK: Public

    @Published var mode: QuranMode {
        didSet {
            if mode == .translation {
                wordPointerEnabled = false
            }
        }
    }

    // MARK: Internal

    weak var listener: MoreMenuListener?

    var state: MoreMenuControlsState

    @Published var wordPointerEnabled: Bool
    @Published var wordPointerType: WordTextType
    @Published var translationFontSize: FontSize
    @Published var arabicFontSize: FontSize

    @Published var twoPagesEnabled: Bool
    @Published var splitPageAndTranslation: Bool
    @Published var verticalScrollingEnabled: Bool
    @Published var markerPopupsEnabled: Bool
    @Published var pageInfoEnabled: Bool
    @Published var orientationLocked: Bool
    @Published var landscapeOrientation: Bool
    @Published var showLinePageDividers: Bool
    @Published var showLinePageSidelines: Bool
    @Published var showArabicText: Bool
    #if QURAN_SYNC
    @Published var indicatorVisibility: AyahIndicatorVisibility
    #endif

    @Published var appearanceMode: AppearanceMode

    func openSearch() {
        logger.info("More Menu: search tapped")
        listener?.onSearchTapped()
    }

    func chooseMushafPrint() {
        logger.info("More Menu: mushaf print tapped")
        listener?.onMushafPrintTapped()
    }

    func openAudioManager() {
        logger.info("More Menu: audio manager tapped")
        listener?.onAudioManagerTapped()
    }

    func goTo() {
        logger.info("More Menu: go to tapped")
        listener?.onGoToTapped()
    }

    func selectTranslations() {
        logger.info("More Menu: translations selections tapped")
        listener?.onTranslationsSelectionsTapped()
    }

    // MARK: Private

    private let model: MoreMenuModel
    private let themeService = ThemeService.shared
    private let wordTextPreferences = WordTextPreferences.shared
    private let preferences = QuranContentStatePreferences.shared
    private let fontSizePreferences = FontSizePreferences.shared

    private var cancellables: Set<AnyCancellable> = []
}
