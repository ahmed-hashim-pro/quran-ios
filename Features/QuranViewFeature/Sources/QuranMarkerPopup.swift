//
//  QuranMarkerPopup.swift
//  QuranEngine
//

import Foundation
import NoorUI
import QuranKit
import QuranLocalization
import UIKit
import UIx

/// Names the juz or hizb quarter that a newly shown page starts, as quran_android's marker popup does.
struct QuranMarkerPopup {
    // MARK: Lifecycle

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    // MARK: Internal

    static let minimumInterval: TimeInterval = 3

    static func name(for page: Page) -> String? {
        guard let quarter = page.quarter else {
            return nil
        }
        return quarter.juz.firstVerse == quarter.firstVerse ? quarter.juz.localizedName : quarter.localizedName
    }

    /// The text to show for the pages now visible, if any. The pages the reader opens on never show one.
    mutating func marker(forVisiblePages pages: [Page]) -> String? {
        defer { previousPages = pages }
        guard let previousPages, previousPages != pages, !pages.isEmpty else {
            return nil
        }
        if let lastShown, now().timeIntervalSince(lastShown) < Self.minimumInterval {
            return nil
        }
        guard let name = pages.sorted().lazy.compactMap(Self.name(for:)).first else {
            return nil
        }
        lastShown = now()
        return name
    }

    // MARK: Private

    private let now: () -> Date
    private var previousPages: [Page]?
    private var lastShown: Date?
}

/// A capsule that fades in over the pages and away by itself, leaving taps and swipes to the pages.
final class QuranMarkerPopupView: UIView {
    // MARK: Lifecycle

    init(text: String) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = UIColor.label.withAlphaComponent(0.85)
        layer.cornerCurve = .continuous

        label.text = text
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .systemBackground
        label.textAlignment = .center
        addAutoLayoutSubview(label)
        label.vc.edges(leading: 18, trailing: 18, top: 9, bottom: 9)

        isAccessibilityElement = true
        accessibilityLabel = text
        accessibilityTraits = .staticText
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    /// `bottomOffset` is measured from the container's bottom edge.
    func show(in container: UIView, bottomOffset: CGFloat) {
        alpha = 0
        container.addAutoLayoutSubview(self)
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: container.centerXAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -bottomOffset),
            widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor, constant: -32),
        ])
        UIAccessibility.post(notification: .announcement, argument: label.text)
        NoorAnimation.animate { self.alpha = 1 } completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.visibleDuration) { [weak self] in
                NoorAnimation.animate { self?.alpha = 0 } completion: {
                    self?.removeFromSuperview()
                }
            }
        }
    }

    // MARK: Private

    private static let visibleDuration: TimeInterval = 1.6

    private let label = UILabel()
}
