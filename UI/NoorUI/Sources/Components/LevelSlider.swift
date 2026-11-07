//
//  LevelSlider.swift
//  QuranEngine
//

import Localization
import SwiftUI

/// A titled slider over whole-number levels that shows its value as a percentage of `scale`.
public struct LevelSlider: View {
    // MARK: Lifecycle

    public init(title: String, subtitle: String? = nil, value: Binding<Int>, range: ClosedRange<Int>, scale: Int) {
        self.title = title
        self.subtitle = subtitle
        _value = value
        self.range = range
        self.scale = scale
    }

    // MARK: Public

    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text(percentage)
                    .monospacedDigit()
                    .foregroundColor(.secondaryLabel)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.secondaryLabel)
            }
            Slider(value: level, in: Double(range.lowerBound) ... Double(range.upperBound), step: 1)
                .accessibilityLabel(title)
                .accessibilityValue(percentage)
        }
    }

    // MARK: Private

    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = .fixedCurrentLocaleNumbers
        return formatter
    }()

    private let title: String
    private let subtitle: String?
    @Binding private var value: Int
    private let range: ClosedRange<Int>
    private let scale: Int

    private var level: Binding<Double> {
        Binding(get: { Double(value) }, set: { value = Int($0.rounded()) })
    }

    private var percentage: String {
        Self.percentFormatter.format(Double(value) / Double(scale))
    }
}

#Preview {
    struct Container: View {
        @State var value = 200

        var body: some View {
            LevelSlider(title: "Text brightness", subtitle: "Brightness of the text when night mode is active", value: $value, range: 0 ... 255, scale: 255)
                .padding()
        }
    }
    return Container()
}
