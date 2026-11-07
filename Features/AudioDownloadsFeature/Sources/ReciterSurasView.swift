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
        // Edit selects surahs to download or delete together, as Android's long press does.
        editController = NavigationEditModeController(
            navigationItem: navigationItem,
            reload: viewModel.objectWillChange.eraseToAnyPublisher(),
            editMode: Binding(
                get: { [weak self] in self?.viewModel.editMode },
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
}

struct ReciterSurasView: View {
    // MARK: Internal

    @StateObject var viewModel: ReciterSurasViewModel

    var body: some View {
        NoorList {
            if !isEditing {
                downloadAllSection
            }
            downloadedSection
            availableSection
        }
        .safeAreaInset(edge: .bottom) {
            if isEditing {
                selectionActions
            }
        }
        .sheet(isPresented: $isChoosingRange) {
            rangeSheet
        }
        .task { await viewModel.start() }
        .errorAlert(error: $viewModel.error)
        .environment(\.editMode, $viewModel.editMode)
    }

    // MARK: Private

    @State private var isChoosingRange = false

    private var isEditing: Bool { viewModel.editMode == .active }

    private var downloadAllSection: some View {
        NoorBasicSection {
            NoorListItem(
                image: .init(.plusCircle),
                title: .text(lAndroid("audio_manager_download_all")),
                action: .sync { isChoosingRange = true }
            )
        }
    }

    @ViewBuilder private var downloadedSection: some View {
        let items: [ReciterSuraItem] = viewModel.items.filter { $0.state == .downloaded }
        if isEditing {
            NoorSection(title: lAndroid("downloaded_translations"), items) { item in
                row(item)
            }
        } else {
            NoorSection(title: lAndroid("downloaded_translations"), items, onDelete: { @Sendable item in viewModel.delete(item.sura) }) { item in
                row(item)
            }
        }
    }

    private var availableSection: some View {
        let items: [ReciterSuraItem] = viewModel.items.filter { $0.state != .downloaded }
        return NoorSection(title: lAndroid("available_translations"), items) { item in
            row(item)
        }
    }

    private var rangeSheet: some View {
        SuraRangeSheet(suras: viewModel.items.map(\.sura)) { first, last in
            isChoosingRange = false
            Task { await viewModel.download(from: first, to: last) }
        } cancel: {
            isChoosingRange = false
        }
    }

    private var selectionActions: some View {
        VStack {
            Button {
                Task { await viewModel.downloadSelection() }
            } label: {
                Text(lAndroid("audio_manager_download_selection")).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectionToDownload.isEmpty)

            Button(role: .destructive) {
                Task { await viewModel.deleteSelection() }
            } label: {
                Text(lAndroid("audio_manager_delete_selection")).frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.selectionToDelete.isEmpty)
        }
        .controlSize(.large)
        .padding()
        .background(.bar)
    }

    @ViewBuilder
    private func row(_ item: ReciterSuraItem) -> some View {
        if isEditing {
            let selected = viewModel.selection.contains(item.sura)
            NoorListItem(
                image: .init(selected ? .checkmark_checked : .checkmark_unchecked, color: selected ? nil : .secondaryLabel),
                title: .text(name(of: item.sura)),
                action: .sync { viewModel.toggleSelection(item.sura) }
            )
            .accessibilityAddTraits(selected ? .isSelected : [])
        } else {
            NoorListItem(title: .text(name(of: item.sura)), accessory: accessory(item))
        }
    }

    private func name(of sura: Sura) -> String {
        "\(sura.localizedSuraNumber). \(sura.localizedName())"
    }

    private func accessory(_ item: ReciterSuraItem) -> NoorListItem.Accessory? {
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

/// quran_android's Download all: the first and last surah to fetch, Al-Fatihah to An-Nas at first.
private struct SuraRangeSheet: View {
    // MARK: Lifecycle

    init(suras: [Sura], download: @escaping (Sura, Sura) -> Void, cancel: @escaping () -> Void) {
        self.suras = suras
        self.download = download
        self.cancel = cancel
        _first = State(initialValue: suras[0])
        _last = State(initialValue: suras[suras.count - 1])
    }

    // MARK: Internal

    var body: some View {
        NavigationView {
            Form {
                Section {
                    picker(lAndroid("from"), selection: $first)
                    picker(lAndroid("to"), selection: $last)
                }
                // Below the pickers, as on Android: in the bar its long title would crowd out the sheet's own.
                Section {
                    Button { download(first, last) } label: {
                        Text(lAndroid("audio_manager_download_selection")).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(lAndroid("audio_manager_download_all"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lAndroid("cancel"), action: cancel)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: Private

    private let suras: [Sura]
    private let download: (Sura, Sura) -> Void
    private let cancel: () -> Void
    @State private var first: Sura
    @State private var last: Sura

    private func picker(_ title: String, selection: Binding<Sura>) -> some View {
        Picker(title, selection: selection) {
            ForEach(suras) { sura in
                Text("\(sura.localizedSuraNumber). \(sura.localizedName())").tag(sura)
            }
        }
    }
}
