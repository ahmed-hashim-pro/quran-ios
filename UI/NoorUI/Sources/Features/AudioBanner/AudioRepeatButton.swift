import Localization
import QuranAudio
import SwiftUI

/// quran_android's audio bar repeat: one tap moves the verse repeats on, and the count sits beside the icon.
struct AudioRepeatButton: View {
    let verseRuns: Runs
    let action: () -> Void

    @ScaledMetric(relativeTo: .caption2) private var badgeOffset = 3

    /// quran_android counts the repeats after the first play, and shows nothing for none.
    static func badge(for verseRuns: Runs) -> String? {
        switch verseRuns {
        case .finite(let count): count > 1 ? NumberFormatter.shared.format(count - 1) : nil
        case .indefinite: "∞"
        }
    }

    var body: some View {
        Button(action: action) {
            AudioControlLabel {
                NoorSystemImage.repeatRange.image
                    .overlay(alignment: .topTrailing) {
                        if let badge = Self.badge(for: verseRuns) {
                            Text(badge)
                                .font(.caption2.weight(.semibold))
                                .fixedSize()
                                // A superscript past the icon's top corner, as Android draws it.
                                .offset(x: badgeOffset, y: -badgeOffset)
                                .accessibilityHidden(true)
                        }
                    }
                    // The symbol doesn't mirror, so the count stays at its top right as on Android.
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        .accessibilityLabel(l("audio.repeat-count"))
        .accessibilityValue(verseRuns.localizedDescription)
    }
}
