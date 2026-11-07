//
//  NightBrightness.swift
//  QuranEngine
//

import SwiftUI
import UIKit

/// Text and background brightness of Quran pages in night mode, as in quran_android.
public struct NightBrightness: Equatable, Sendable {
    // MARK: Lifecycle

    public init(text: Int, background: Int) {
        self.text = Self.textRange.clamped(text)
        self.background = Self.backgroundRange.clamped(background)
    }

    // MARK: Public

    public static let textRange = 0 ... 255
    public static let backgroundRange = 0 ... 64
    public static let `default` = NightBrightness(text: 255, background: 0)

    public let text: Int
    public let background: Int

    /// quran_android lifts the text with the background so the page keeps its contrast.
    public var textLevel: CGFloat {
        min(255, 50 * log1p(CGFloat(background)) + CGFloat(text)) / 255
    }

    public var backgroundLevel: CGFloat {
        CGFloat(background) / 255
    }

    // MARK: Internal

    func adjustText(_ color: UIColor) -> UIColor {
        guard textLevel < 1 else { return color }
        return color.mapRGB { $0 * textLevel }
    }

    /// Mixes white into the theme's night background, which gives Android's gray on a black page.
    func adjustBackground(_ color: UIColor) -> UIColor {
        guard background > 0 else { return color }
        return color.mapRGB { $0 + (1 - $0) * backgroundLevel }
    }
}

extension ClosedRange<Int> {
    func clamped(_ value: Int) -> Int {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}

private extension UIColor {
    func mapRGB(_ transform: (CGFloat) -> CGFloat) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return self }
        return UIColor(red: transform(red), green: transform(green), blue: transform(blue), alpha: alpha)
    }
}

// MARK: - Environment

private struct NightBrightnessKey: EnvironmentKey {
    static let defaultValue = NightBrightness.default
}

extension EnvironmentValues {
    public var nightBrightness: NightBrightness {
        get { self[NightBrightnessKey.self] }
        set { self[NightBrightnessKey.self] = newValue }
    }
}
