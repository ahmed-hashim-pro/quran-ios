//
//  TranslationStrip.swift
//  QuranEngine
//

import Localization
import NoorUI
import SwiftUI
import TranslationService
import UIKit

@MainActor
enum TranslationStripBuilder {
    static func build(
        localTranslationsRetriever: LocalTranslationsRetriever?,
        selectTranslations: @escaping @MainActor () -> Void
    ) -> UIViewController {
        let viewModel = TranslationStripViewModel(
            localTranslationsRetriever: localTranslationsRetriever,
            selectTranslations: selectTranslations
        )
        let viewController = UIHostingController(rootView: TranslationStrip(viewModel: viewModel))
        viewController.view.backgroundColor = nil
        return viewController
    }
}

/// Sits under the reader's bar in translation mode, as quran_android's text-mode strip does.
struct TranslationStrip: View {
    @ObservedObject var viewModel: TranslationStripViewModel

    var body: some View {
        HStack {
            Button(action: viewModel.openTranslations) {
                HStack(spacing: 6) {
                    NoorSystemImage.mushafs.image
                    Text(viewModel.sourceName)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .imageScale(.small)
                }
                .font(.footnote.weight(.semibold))
                .padding(.horizontal)
                .frame(minHeight: minimumTapLength)
                .readerChromeBackground()
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(lAndroid("prefs_translations"))
            .accessibilityValue(viewModel.sourceName)
            .accessibilityAddTraits(.isButton)

            Spacer(minLength: 0)

            HStack(spacing: 0) {
                Button(action: viewModel.decreaseFontSize) {
                    Text(l("menu.fontSizeLetter") + "−")
                        .font(.footnote.weight(.bold))
                        .frame(minWidth: minimumTapLength, minHeight: minimumTapLength)
                }
                .disabled(!viewModel.canDecreaseFontSize)

                Button(action: viewModel.increaseFontSize) {
                    Text(l("menu.fontSizeLetter") + "+")
                        .font(.body.weight(.bold))
                        .frame(minWidth: minimumTapLength, minHeight: minimumTapLength)
                }
                .disabled(!viewModel.canIncreaseFontSize)
            }
            .buttonStyle(.plain)
            .readerChromeBackground()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(l("menu.translationFontSize"))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: viewModel.increaseFontSize()
                case .decrement: viewModel.decreaseFontSize()
                @unknown default: break
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    // MARK: Private

    @ScaledMetric private var minimumTapLength = 44.0
}
