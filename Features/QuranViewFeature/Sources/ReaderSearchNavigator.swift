//
//  ReaderSearchNavigator.swift
//  QuranEngine
//

import FeaturesSupport
import QuranAnnotations
import QuranKit

/// Sends a search result back to the reader that opened the search, rather than opening another reader.
@MainActor
final class ReaderSearchNavigator: QuranNavigator {
    // MARK: Lifecycle

    init(navigate: @escaping (Page, AyahNumber?) -> Void) {
        self.navigate = navigate
    }

    // MARK: Internal

    func navigateTo(page: Page, lastPage: LastPage?) {
        navigate(page, nil)
    }

    func navigateTo(ayah: AyahNumber, lastPage: LastPage?) {
        navigate(ayah.page, ayah)
    }

    // MARK: Private

    private let navigate: (Page, AyahNumber?) -> Void
}
