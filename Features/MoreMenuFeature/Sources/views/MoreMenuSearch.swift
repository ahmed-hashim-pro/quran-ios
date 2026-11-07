//
//  MoreMenuSearch.swift
//  QuranEngine
//

import Localization
import NoorUI
import SwiftUI

struct MoreMenuSearch: View {
    var body: some View {
        NoorListItem(
            title: .text(lAndroid("menu_search")),
            accessory: .disclosureIndicator
        )
        .padding()
    }
}
