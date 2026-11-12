//
//  MoreMenuOrientationLock.swift
//  QuranEngine
//

import Localization
import NoorUI
import SwiftUI

/// quran_android's Lock orientation, with Landscape dimmed until the lock is on.
struct MoreMenuOrientationLock: View {
    @Binding var locked: Bool
    @Binding var landscape: Bool

    var body: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $locked) {
                label(
                    title: "prefs_lock_orientation_title",
                    summary: locked ? "prefs_lock_orientation_summary_on" : "prefs_lock_orientation_summary_off"
                )
            }
            .padding()

            Divider()
                .padding(.leading)

            Toggle(isOn: $landscape) {
                label(
                    title: "prefs_landscape_orientation_title",
                    summary: landscape ? "prefs_landscape_orientation_summary_on" : "prefs_landscape_orientation_summary_off"
                )
            }
            .disabled(!locked)
            .padding()
        }
    }

    private func label(title: String, summary: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(lAndroid(title))
            Text(lAndroid(summary))
                .font(.footnote)
                .foregroundColor(.secondaryLabel)
        }
    }
}

#Preview {
    MoreMenuOrientationLock(locked: .constant(true), landscape: .constant(false))
}
