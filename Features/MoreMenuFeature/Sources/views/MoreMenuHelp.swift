//
//  MoreMenuHelp.swift
//  QuranEngine
//

import Localization
import NoorUI
import SwiftUI

struct MoreMenuHelp: View {
    var body: some View {
        NoorListItem(
            title: .text(lAndroid("menu_help")),
            accessory: .disclosureIndicator
        )
        .padding()
    }
}
