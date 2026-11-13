//
//  AudioBannerViewUI+Previews.swift
//  QuranEngine
//

import SwiftUI
import UIx

#Preview("Compact Playing") {
    let actions = AudioBannerActions(
        play: {},
        pause: {},
        resume: {},
        stop: {},
        backward: {},
        forward: {},
        cycleRepeat: {},
        cancelDownloading: {},
        acceptDownload: {},
        declineDownload: {},
        reciters: {},
        more: {},
        setPlaybackRate: { _ in }
    )
    AudioBannerViewUI(
        state: .playing(paused: false, rate: 1, reciter: "Mishary Al-afasy", nowPlaying: "Al-Baqarah · ayah 255"),
        actions: actions,
        options: .init()
    )
    .frame(width: 300)
    .background(Color.systemGroupedBackground)
}

#Preview {
    struct PreviewView: View {
        let actions = AudioBannerActions(
            play: {},
            pause: {},
            resume: {},
            stop: {},
            backward: {},
            forward: {},
            cycleRepeat: {},
            cancelDownloading: {},
            acceptDownload: {},
            declineDownload: {},
            reciters: {},
            more: {},
            setPlaybackRate: { _ in }
        )

        let readyToPlay = AudioBannerState.readyToPlay(reciter: "Mishary Al-afasy")
        let playing = AudioBannerState.playing(paused: false, rate: 1.0, reciter: "Mishary Al-afasy")
        let downloading = AudioBannerState.downloading(progress: 0.7)
        var state: AudioBannerState {
            switch counter % 3 {
            case 0: readyToPlay
            case 1: playing
            default: downloading
            }
        }

        @State var counter: Int = 1

        var body: some View {
            VStack {
                Spacer()
                Button {
                    counter += 1
                } label: {
                    Text("Rotate")
                }
                Spacer()
                Group {
                    AudioBannerViewUI(state: state, actions: actions, options: .init())
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.systemGroupedBackground)
        }
    }

    return PreviewView()
}

#Preview("Audio option indicators") {
    let actions = AudioBannerActions(
        play: {}, pause: {}, resume: {}, stop: {}, backward: {}, forward: {}, cycleRepeat: {},
        cancelDownloading: {}, acceptDownload: {}, declineDownload: {}, reciters: {}, more: {}, setPlaybackRate: { _ in }
    )
    ScrollView {
        VStack {
            AudioBannerViewUI(state: .confirmingDownload, actions: actions, options: .init())
            AudioBannerViewUI(state: .downloading(progress: 0.3), actions: actions, options: .init())
            AudioBannerViewUI(state: .downloading(progress: 0.3), actions: actions, options: .init(rate: 0.5))
            AudioBannerViewUI(state: .readyToPlay(reciter: "Mishary Al-afasy"), actions: actions, options: .init())
            AudioBannerViewUI(
                state: .readyToPlay(reciter: "Mishary Al-afasy"), actions: actions,
                options: .init(rate: 0.5, verseRuns: .finite(3), rangeRuns: .finite(2))
            )
            AudioBannerViewUI(
                state: .playing(paused: false, rate: 0.5, reciter: "Mishary Al-afasy"), actions: actions,
                options: .init(rate: 0.5, verseRuns: .finite(3), rangeRuns: .finite(2))
            )
            AudioBannerViewUI(
                state: .playing(paused: true, rate: 1, reciter: "Mishary Al-afasy"), actions: actions,
                options: .init(rangeRuns: .indefinite)
            )
            AudioBannerViewUI(
                state: .playing(paused: true, rate: 1, reciter: "Mishary Al-afasy"), actions: actions,
                options: .init()
            )
            AudioBannerViewUI(
                state: .readyToPlay(reciter: "مشاري العفاسي"), actions: actions,
                options: .init()
            )
            .environment(\.layoutDirection, .rightToLeft)
            .dynamicTypeSize(.xxLarge)
            AudioBannerViewUI(
                state: .readyToPlay(reciter: "مشاري العفاسي"), actions: actions,
                options: .init(rate: 0.5, verseRuns: .finite(3), rangeRuns: .finite(2))
            )
            .environment(\.layoutDirection, .rightToLeft)
            .dynamicTypeSize(.xxLarge)
            AudioBannerViewUI(
                state: .readyToPlay(reciter: "مشاري العفاسي"), actions: actions,
                options: .init(rate: 0.5, verseRuns: .finite(3), rangeRuns: .finite(2))
            )
            .environment(\.layoutDirection, .rightToLeft)
            .dynamicTypeSize(.accessibility1)
        }
        .padding(.vertical)
    }
    .background(Color.systemGroupedBackground)
}
