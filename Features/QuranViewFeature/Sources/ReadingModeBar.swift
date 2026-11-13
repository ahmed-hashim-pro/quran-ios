//
//  ReadingModeBar.swift
//  QuranEngine
//

import Combine
import NoorUI
import SwiftUI
import UIKit
import VLogging

@MainActor
enum ReadingModeBarBuilder {
    static func build() -> UIViewController {
        let viewModel = ReadingModeBarViewModel(themeService: .shared)
        // The bar floats over the page, so it stops growing before it crowds it.
        let view = ReadingModeBar(viewModel: viewModel)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        let viewController = UIHostingController(rootView: view)
        viewController.view.backgroundColor = nil
        if #available(iOS 16.0, *) {
            viewController.sizingOptions = .intrinsicContentSize
        }
        if #available(iOS 16.4, *) {
            viewController.safeAreaRegions = []
        }
        return viewController
    }
}

@MainActor
final class ReadingModeBarViewModel: ObservableObject {
    // MARK: Lifecycle

    init(themeService: ThemeService) {
        self.themeService = themeService
        themeStyle = themeService.themeStyle
        themeService.themeStylePublisher
            .sink { [weak self] in self?.themeStyle = $0 }
            .store(in: &cancellables)
    }

    // MARK: Internal

    @Published private(set) var themeStyle: ThemeStyle

    func select(_ mode: ReadingMode) {
        logger.info("Reading mode bar: \(mode) tapped")
        mode.apply(to: themeService)
    }

    // MARK: Private

    private let themeService: ThemeService
    private var cancellables: Set<AnyCancellable> = []
}

/// quran_android's floating Day, Sepia and Night switcher above the audio bar.
struct ReadingModeBar: View {
    // MARK: Internal

    @ObservedObject var viewModel: ReadingModeBarViewModel

    var body: some View {
        let selected = ReadingMode(themeStyle: viewModel.themeStyle, isDark: colorScheme == .dark)
        HStack(spacing: 4) {
            ForEach(ReadingMode.allCases, id: \.self) { mode in
                chip(mode, isSelected: mode == selected)
            }
        }
        .padding(.horizontal, barPadding)
        .readerChromeBackground()
    }

    // MARK: Private

    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric private var chipHeight = 34.0
    @ScaledMetric private var chipPadding = 16.0
    @ScaledMetric private var barPadding = 5.0

    private func chip(_ mode: ReadingMode, isSelected: Bool) -> some View {
        Button {
            viewModel.select(mode)
        } label: {
            Text(mode.title)
                .font(.footnote.weight(.bold))
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.onAccent : Color.secondary)
                .padding(.horizontal, chipPadding)
                .frame(minHeight: chipHeight)
                .background(isSelected ? Color.accentColor : Color.clear, in: Capsule())
                // Inside the label, so the whole height of the bar takes the tap.
                .padding(.vertical, barPadding)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
