//
//  PagesView.swift
//
//
//  Created by Mohamed Afifi on 2024-10-06.
//

import QuranKit
import QuranPagesFeature
import QuranText
import QuranTextKit
import SwiftUI
import UIx

struct PagesView: View {
    // MARK: Internal

    @StateObject var viewModel: ContentViewModel

    var body: some View {
        GeometryReader { geometry in
            let twoPages = pagingStrategy(with: geometry)
            let besideTranslation = viewModel.showsPageBesideTranslation(in: twoPages)
            let strategy = besideTranslation ? PagingStrategy.singlePage : twoPages
            QuranPaginationView(
                pagingStrategy: strategy,
                selection: $viewModel.visiblePages,
                pages: viewModel.deps.quran.pages,
                onVisiblePageChanged: viewModel.onVisiblePageChanged
            ) { page in
                Group {
                    if besideTranslation {
                        PageBesideTranslation(page: page) {
                            arabic(page)
                        } translation: {
                            translation(page)
                        }
                    } else {
                        switch viewModel.quranMode {
                        case .arabic:
                            arabic(page)
                        case .translation:
                            translation(page)
                        }
                    }
                }
                .onAppear { viewModel.onPageContentAppear(pagingStrategy: strategy) }
            }
            .id(ContentKey(mode: viewModel.quranMode, besideTranslation: besideTranslation))
        }
        // Measure without the keyboard. A keyboard, even one shown by a presented editor,
        // would make portrait look landscape and flip the reader to double pages.
        .ignoresSafeArea(.keyboard)
        .collectGeometryActions($viewModel.geometryActions)
    }

    // MARK: Private

    private struct ContentKey: Hashable {
        let mode: QuranMode
        let besideTranslation: Bool
    }

    @ViewBuilder
    private func arabic(_ page: Page) -> some View {
        #if QURAN_SYNC
        viewModel.deps.imageDataSourceBuilder.build(at: page) {
            viewModel.onAyahNumberTapped($0, at: $1)
        } onPageReadingBookmarkTap: {
            viewModel.onPageReadingBookmarkTapped(page, at: $0)
        }
        #else
        viewModel.deps.imageDataSourceBuilder.build(at: page)
        #endif
    }

    @ViewBuilder
    private func translation(_ page: Page) -> some View {
        #if QURAN_SYNC
        viewModel.deps.translationDataSourceBuilder.build(at: page) {
            viewModel.onAyahNumberTapped($0, at: $1)
        }
        #else
        viewModel.deps.translationDataSourceBuilder.build(at: page)
        #endif
    }

    private func pagingStrategy(with geometry: GeometryProxy) -> PagingStrategy {
        // If portrait
        if geometry.size.height > geometry.size.width {
            return .singlePage
        }

        if !TwoPagesUtils.hasEnoughHorizontalSpace() {
            return .singlePage
        }

        return viewModel.pagingStrategy
    }
}

/// quran_android's split page: the Quran page on the side it takes in a printed spread, its translation on the other.
private struct PageBesideTranslation<Arabic: View, Translation: View>: View {
    // MARK: Lifecycle

    init(page: Page, @ViewBuilder arabic: () -> Arabic, @ViewBuilder translation: () -> Translation) {
        self.page = page
        self.arabic = arabic()
        self.translation = translation()
    }

    // MARK: Internal

    let page: Page
    let arabic: Arabic
    let translation: Translation

    var body: some View {
        HStack(spacing: 0) {
            if page.isRightSide {
                side(translation)
                side(arabic)
            } else {
                side(arabic)
                side(translation)
            }
        }
        // The sides follow the printed spread in either language; each side keeps the app's own direction.
        .environment(\.layoutDirection, .leftToRight)
    }

    // MARK: Private

    @Environment(\.layoutDirection) private var direction

    private func side(_ content: some View) -> some View {
        content
            .environment(\.layoutDirection, direction)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
