//
//  MoreMenuFocusMode.swift
//  QuranEngine
//

import Localization
import SwiftUI

struct MoreMenuFocusMode: View {
    @Binding var enabled: Bool

    var body: some View {
        Toggle(lAndroid("focus_mode"), isOn: $enabled)
            .padding()
    }
}
