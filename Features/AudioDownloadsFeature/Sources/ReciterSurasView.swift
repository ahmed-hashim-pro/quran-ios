//
//  ReciterSurasView.swift
//  QuranEngine
//

import Combine
import Localization
import NoorUI
import QuranKit
import QuranLocalization
import SwiftUI
import UIx

/// quran_android's audio manager for one reciter: every surah, downloaded or not.
final class ReciterSurasViewController: UIHostingController<ReciterSurasView> {
    // MARK: Lifecycle

    init(viewModel: ReciterSurasViewModel) {
        self.viewModel = viewModel
        super.init(rootView: ReciterSurasView(viewModel: viewModel))
        title = viewModel.reciter.localizedName
        editController = NavigationEditModeController(
            navigationItem: navigationItem,
            reload: viewModel.objectWillChange.eraseToAnyPublisher(),
            editMode: Binding(
                get: { [weak self] in self?.currentEditMode },
                set: { [weak self] value in self?.viewModel.editMode = value ?? .inactive }
            )
        )
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private let viewModel: ReciterSurasViewModel
    private var editController: NavigationEditModeController?

    private var currentEditMode: EditMode? {
        viewModel.downloaded.isEmpty ? nil : viewModel.editMode
    }
}

struct ReciterSurasView: View {
    // MARK: Internal

    @StateObject var viewModel: ReciterSurasViewModel

    var body: some View {
        let items = viewModel.items
        NoorList {
            NoorSection(
                title: lAndroid("downloaded_translations"),
                items.filter { $0.state == .downloaded },
                onDelete: { @Sendable item in viewModel.delete(item.sura) }
            ) { item in
                NoorListItem(title: .text(name(of: item.sura)))
            }

            NoorSection(
                title: lAndroid("available_translations"),
                items.filter { $0.state != .downloaded }
            ) { item in
                NoorListItem(title: .text(name(of: item.sura)), accessory: accessory(item))
            }
        }
        .task { await viewModel.start() }
        .errorAlert(error: $viewModel.error)
        .environment(\.editMode, $viewModel.editMode)
    }

    // MARK: Private

    private func name(of sura: Sura) -> String {
        "\(sura.localizedSuraNumber). \(sura.localizedName())"
    }

    private func accessory(_ item: ReciterSuraItem) -> NoorListItem.Accessory? {
        guard viewModel.editMode != .active else {
            return nil
        }
        switch item.state {
        case .downloaded:
            return nil
        case .notDownloaded:
            return .download(.download) { await viewModel.download(item.sura) }
        case .downloading(let progress):
            let type = progress < 0.001 ? DownloadType.pending : .downloading(progress: progress)
            return .download(type) { await viewModel.cancel(item.sura) }
        }
    }
}
