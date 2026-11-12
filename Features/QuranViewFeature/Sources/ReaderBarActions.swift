//
//  ReaderBarActions.swift
//  QuranEngine
//

import CoreGraphics

/// quran_android puts its reader actions on the bar only if there is room, and the rest in the overflow menu.
enum ReaderBarActions {
    /// How many actions sit beside the overflow: AppCompat's `ActionBarPolicy` slots, less the overflow's own.
    /// Five actions and the overflow would leave an iPhone's title about 30 to 60 points.
    static func count(for size: CGSize) -> Int {
        let slots = if size.width > 600 {
            5
        } else if size.width >= 500 || (size.width > 480 && size.height > 640) {
            4
        } else if size.width >= 360 {
            3
        } else {
            2
        }
        return slots - 1
    }
}
