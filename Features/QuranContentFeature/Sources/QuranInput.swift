//
//  QuranInput.swift
//  Quran
//
//  Created by Afifi, Mohamed on 9/2/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import QuranAnnotations
import QuranKit

public struct QuranInput {
    // MARK: Lifecycle

    public init(initialPage: Page, lastPage: LastPage?, navigationAyah: AyahNumber?, autoPlay: Bool = false) {
        self.initialPage = initialPage
        self.lastPage = lastPage
        self.navigationAyah = navigationAyah
        self.autoPlay = autoPlay
    }

    // MARK: Public

    public let initialPage: Page
    public let lastPage: LastPage?
    public let navigationAyah: AyahNumber?
    /// Plays the page the reader opens on once, streamed, as quran_android's Home Read & listen does.
    public let autoPlay: Bool
}
