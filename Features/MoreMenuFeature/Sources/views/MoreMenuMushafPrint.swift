//
//  MoreMenuMushafPrint.swift
//  QuranEngine
//

import Localization
import NoorUI
import SwiftUI

struct MoreMenuMushafPrint: View {
    var body: some View {
        NoorListItem(
            title: .text(lAndroid("prefs_page_type_title")),
            subtitle: .init(text: .text(lAndroid("prefs_page_type_summary")), location: .bottom),
            accessory: .disclosureIndicator
        )
        .padding()
    }
}
