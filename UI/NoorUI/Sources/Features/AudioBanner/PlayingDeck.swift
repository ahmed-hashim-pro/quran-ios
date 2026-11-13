//
//  PlayingDeck.swift
//  QuranEngine
//

import Localization
import SwiftUI

/// quran_android's playing deck: the reciter at the reading start, which a tap changes, and at the end
/// the surah and ayah being recited.
struct PlayingDeck: View {
    let reciter: String
    let nowPlaying: MultipartText?
    let action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: action) {
                HStack(spacing: 6) {
                    NoorSystemImage.reciter.image
                    Text(reciter)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                }
                .frame(maxWidth: .infinity, minHeight: AudioControlMetrics.minimumTapLength, alignment: .leading)
                .contentShape(Rectangle())
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(l("audio.reciter"))
            .accessibilityValue(reciter)
            .accessibilityAddTraits(.isButton)

            if let nowPlaying {
                // Like Android's, the reciter's name gives way before the surah and ayah do.
                nowPlaying.view(ofSize: .footnote, allowsWrapping: false)
                    .foregroundStyle(.secondary)
                    .layoutPriority(1)
            }
        }
        .font(.footnote)
        .padding(.horizontal)
    }
}
