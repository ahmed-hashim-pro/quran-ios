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
            title: .text(l("reading.selector.title")),
            accessory: .disclosureIndicator
        )
        .padding()
    }
}
