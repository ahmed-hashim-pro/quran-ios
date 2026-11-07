//
//  MoreMenuAudioManager.swift
//  QuranEngine
//

import Localization
import NoorUI
import SwiftUI

struct MoreMenuAudioManager: View {
    var body: some View {
        NoorListItem(
            title: .text(lAndroid("audio_manager")),
            accessory: .disclosureIndicator
        )
        .padding()
    }
}
