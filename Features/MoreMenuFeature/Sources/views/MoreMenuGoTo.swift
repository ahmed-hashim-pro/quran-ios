//
//  MoreMenuGoTo.swift
//  QuranEngine
//

import Localization
import NoorUI
import SwiftUI

struct MoreMenuGoTo: View {
    var body: some View {
        NoorListItem(
            title: .text(lAndroid("menu_jump")),
            accessory: .disclosureIndicator
        )
        .padding()
    }
}
