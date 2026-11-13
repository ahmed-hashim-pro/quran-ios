//
//  QuranViewController+Navigating.swift
//  QuranEngine
//

import QuranKit

extension QuranViewController: QuranReaderNavigating {
    func navigate(to page: Page) {
        interactor.navigate(to: .page(page))
    }

    func navigate(to ayah: AyahNumber) {
        interactor.navigate(to: .ayah(ayah))
    }
}
