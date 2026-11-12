//
//  TranslationStripViewModel.swift
//  QuranEngine
//

import Combine
import Foundation
import Localization
import QuranText
import QuranTextKit
import TranslationService
import VLogging

/// quran_android's translation-mode strip: the translations shown, which opens the translations list,
/// and the translation text size.
@MainActor
final class TranslationStripViewModel: ObservableObject {
    // MARK: Lifecycle

    init(localTranslationsRetriever: LocalTranslationsRetriever?, selectTranslations: @escaping @MainActor () -> Void) {
        self.localTranslationsRetriever = localTranslationsRetriever
        self.selectTranslations = selectTranslations
        fontSize = fontSizePreferences.translationFontSize

        fontSizePreferences.$translationFontSize
            .sink { [weak self] in self?.fontSize = $0 }
            .store(in: &cancellables)
        selectedTranslationsPreferences.$selectedTranslationIds
            .sink { [weak self] in self?.loadTranslationNames(ids: $0) }
            .store(in: &cancellables)
        loadTranslationNames(ids: selectedTranslationsPreferences.selectedTranslationIds)
    }

    // MARK: Internal

    @Published private(set) var fontSize: FontSize
    @Published private(set) var translationNames: [String] = []

    var sourceName: String {
        Self.sourceName(translationNames)
    }

    var canDecreaseFontSize: Bool {
        fontSize.smaller != nil
    }

    var canIncreaseFontSize: Bool {
        fontSize.larger != nil
    }

    /// Android's chip names the first translation and counts the others, or offers translations when none is chosen.
    static func sourceName(_ names: [String]) -> String {
        guard let first = names.first else {
            return lAndroid("menu_translation")
        }
        guard names.count > 1 else {
            return first
        }
        return "\(first)  +\(NumberFormatter.shared.format(names.count - 1))"
    }

    func decreaseFontSize() {
        if let smaller = fontSize.smaller {
            logger.info("Translation strip: decrease font size to \(smaller)")
            fontSizePreferences.translationFontSize = smaller
        }
    }

    func increaseFontSize() {
        if let larger = fontSize.larger {
            logger.info("Translation strip: increase font size to \(larger)")
            fontSizePreferences.translationFontSize = larger
        }
    }

    func openTranslations() {
        logger.info("Translation strip: translations tapped")
        selectTranslations()
    }

    // MARK: Private

    private let localTranslationsRetriever: LocalTranslationsRetriever?
    private let selectTranslations: @MainActor () -> Void
    private let fontSizePreferences = FontSizePreferences.shared
    private let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
    private var cancellables: Set<AnyCancellable> = []
    private var loadTask: Task<Void, Never>?

    private func loadTranslationNames(ids: [Translation.ID]) {
        guard let localTranslationsRetriever else {
            return
        }
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            do {
                let translations = try await localTranslationsRetriever.getLocalTranslations()
                guard !Task.isCancelled else {
                    return
                }
                let translationsById = Dictionary(translations.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
                self?.translationNames = ids.compactMap { translationsById[$0]?.translationName }
            } catch {
                logger.error("Translation strip: couldn't load translations. \(error)")
            }
        }
    }
}

extension FontSize {
    /// A lower raw value is a larger size.
    var larger: FontSize? {
        FontSize(rawValue: rawValue - 1)
    }

    var smaller: FontSize? {
        FontSize(rawValue: rawValue + 1)
    }
}
