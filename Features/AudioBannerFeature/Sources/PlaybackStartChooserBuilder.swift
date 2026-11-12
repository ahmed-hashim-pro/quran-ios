//
//  PlaybackStartChooserBuilder.swift
//

import Localization
import NoorUI
import QuranKit
import SwiftUI
import UIKit
import UIx

@MainActor
struct PlaybackStartChooserBuilder {
    func build(
        reciter: String,
        choices: [PlaybackStart],
        choose: @escaping @MainActor @Sendable (PlaybackStart) -> Void,
        close: @escaping Action
    ) -> UIViewController {
        let items = choices.map { choice in
            PlaybackStartChoiceItem(image: choice.image, title: choice.title, subtitle: choice.subtitle) {
                choose(choice)
            }
        }
        let controller = UIHostingController(rootView: PlaybackStartChooser(reciter: reciter, items: items, close: close))
        controller.modalPresentationStyle = .pageSheet
        if let sheet = controller.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        return controller
    }
}

extension PlaybackStart {
    var image: NoorSystemImage {
        switch self {
        case .lastRange: .repeatRange
        case .page: .play
        case .sura: .book
        }
    }

    var title: MultipartText {
        switch self {
        case .lastRange: .text(lAndroid("playback_prompt_last_range"))
        case .page: .text(lAndroid("starting_page_label"))
        case .sura(let sura): "\(sura: sura)"
        }
    }

    var subtitle: MultipartText {
        switch self {
        case .lastRange(let range):
            let verses: MultipartText = "\(ayahRange: range.start ... range.end)"
            return range.hasRepeats ? "\(verses) · \(lAndroid("playback_prompt_repeat_suffix"))" : verses
        case .page(let page):
            return .text(lFormat("playback_prompt_page_sub", table: .android, NumberFormatter.shared.format(page.pageNumber)))
        case .sura:
            return .text(lAndroid("playback_prompt_sura_sub"))
        }
    }
}
