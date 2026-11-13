import Foundation
import Localization
import NoorUI
import QuranKit

/// quran_android's playing deck reads "<surah> · ayah <n>" for the ayah being recited.
enum AudioBarNowPlaying {
    static func text(for ayah: AyahNumber) -> MultipartText {
        MultipartText.localizedFormat(
            "audiobar_now_playing",
            table: .android,
            "\(sura: ayah.sura)",
            .text(NumberFormatter.shared.format(ayah.ayah))
        )
    }
}
