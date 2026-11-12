//
//  PlaybackStartChooser.swift
//

import Localization
import SwiftUI
import UIx

public struct PlaybackStartChoiceItem: Identifiable {
    // MARK: Lifecycle

    public init(image: NoorSystemImage, title: MultipartText, subtitle: MultipartText, action: @escaping Action) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    // MARK: Public

    public let id = UUID()

    // MARK: Internal

    let image: NoorSystemImage
    let title: MultipartText
    let subtitle: MultipartText
    let action: Action
}

/// quran_android's sheet asking where Play starts: the remembered range, the page, or a surah starting on it.
public struct PlaybackStartChooser: View {
    // MARK: Lifecycle

    public init(reciter: String, items: [PlaybackStartChoiceItem], close: @escaping @MainActor @Sendable () -> Void) {
        self.reciter = reciter
        self.items = items
        self.close = close
    }

    // MARK: Public

    public var body: some View {
        CocoaNavigationView {
            NoorList {
                NoorBasicSection(title: reciter.isEmpty ? nil : lFormat("playback_prompt_reciter", table: .android, reciter)) {
                    ForEach(items) { item in
                        NoorListItem(
                            image: .init(item.image),
                            title: item.title,
                            subtitle: .init(text: item.subtitle, location: .bottom),
                            action: .sync(item.action)
                        )
                    }
                }
            }
            .noorListIconColumn()
            .navigationTitle(lAndroid("playback_prompt_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                CloseToolbarItem(action: close)
            }
        }
        .standardAppearance(.opaqueBackground().backgroundColor(.systemBackground))
        .scrollEdgeAppearance(.opaqueBackground().backgroundColor(.systemBackground))
    }

    // MARK: Private

    private let reciter: String
    private let items: [PlaybackStartChoiceItem]
    private let close: @MainActor @Sendable () -> Void
}

#Preview {
    PlaybackStartChooser(
        reciter: "Mishary Al-afasy",
        items: [
            PlaybackStartChoiceItem(image: .repeatRange, title: "Repeat the last range", subtitle: "Al-Fatihah 1–7 · with repeat") {},
            PlaybackStartChoiceItem(image: .play, title: "Beginning of Page", subtitle: "Page 106") {},
            PlaybackStartChoiceItem(image: .book, title: "Al-Ma'idah", subtitle: "From the start of the surah") {},
        ],
        close: {}
    )
}
