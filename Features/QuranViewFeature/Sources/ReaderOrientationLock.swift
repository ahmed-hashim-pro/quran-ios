//
//  ReaderOrientationLock.swift
//  QuranEngine
//

import UIKit

/// quran_android's Lock orientation and Landscape settings, as the orientations the reader allows.
enum ReaderOrientationLock {
    /// Nil follows the device. iPad windows are resizable, and iPadOS doesn't reliably honour an app's
    /// orientations there, so the lock is a phone setting.
    static func supportedOrientations(
        locked: Bool,
        landscape: Bool,
        idiom: UIUserInterfaceIdiom
    ) -> UIInterfaceOrientationMask? {
        guard locked, idiom == .phone else {
            return nil
        }
        return landscape ? .landscape : .portrait
    }

    static func isAvailable(on idiom: UIUserInterfaceIdiom) -> Bool {
        idiom == .phone
    }
}
