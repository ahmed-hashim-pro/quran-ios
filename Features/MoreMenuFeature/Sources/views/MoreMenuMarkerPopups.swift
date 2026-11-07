//
//  MoreMenuMarkerPopups.swift
//  QuranEngine
//

import Localization
import SwiftUI

struct MoreMenuMarkerPopups: View {
    @Binding var enabled: Bool

    var body: some View {
        Toggle(isOn: $enabled) {
            VStack(alignment: .leading) {
                Text(lAndroid("prefs_display_marker_title"))
                Text(lAndroid("prefs_display_marker_summary"))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
