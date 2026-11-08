//
//  MoreMenuSplitPage.swift
//  QuranEngine
//

import Localization
import NoorUI
import SwiftUI

/// quran_android's Quran and translation in dual mode, dimmed while two pages are off.
struct MoreMenuSplitPage: View {
    @Binding var enabled: Bool
    let available: Bool

    var body: some View {
        Toggle(isOn: $enabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text(lAndroid("prefs_split_page_and_translation_title"))
                Text(lAndroid("prefs_split_page_and_translation_summary"))
                    .font(.footnote)
                    .foregroundColor(.secondaryLabel)
            }
        }
        .disabled(!available)
        .padding()
    }
}
