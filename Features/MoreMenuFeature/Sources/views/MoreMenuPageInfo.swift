//
//  MoreMenuPageInfo.swift
//  QuranEngine
//

import Localization
import SwiftUI

struct MoreMenuPageInfo: View {
    @Binding var enabled: Bool

    var body: some View {
        Toggle(isOn: $enabled) {
            VStack(alignment: .leading) {
                Text(lAndroid("prefs_overlay_page_info_title"))
                Text(lAndroid("prefs_overlay_page_info_summary"))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
