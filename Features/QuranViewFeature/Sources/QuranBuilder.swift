//
//  QuranBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AnnotationsService
import AppDependencies
import AudioBannerFeature
import AudioDownloadsFeature
import AyahMenuFeature
#if QURAN_SYNC
import BookmarksFeature
#endif
import MoreMenuFeature
import NoteEditorFeature
#if QURAN_SYNC
import NotesFeature
#endif
import QuranContentFeature
import QuranKit
import ReadingService
import SearchFeature
#if QURAN_SYNC
import ReadingBookmarkMenuFeature
#endif
import TranslationsFeature
import TranslationVerseFeature
import UIKit
import WordPointerFeature

/// Tags `ayah` in the app's own bookmark tags, presenting from `presenter`.
public typealias QuranAyahTagger = @MainActor (_ ayah: AyahNumber, _ presenter: UIViewController) -> Void

@MainActor
public struct QuranBuilder {
    // MARK: Lifecycle

    /// The ayah menu offers quran_android's Tag only when `tagAyah` is given.
    public init(container: AppDependencies, tagAyah: QuranAyahTagger? = nil) {
        self.container = container
        self.tagAyah = tagAyah
    }

    // MARK: Public

    public func build(input: QuranInput) -> UIViewController {
        let overlayService = VerseOverlayService()

        let reading = ReadingPreferences.shared.reading
        let quran = reading.quran
        #if QURAN_SYNC
        let noteService = container.mobileSyncNoteService()
        let annotationsObserver = QuranAnnotationsObserver(
            noteService: noteService,
            highlightService: container.ayahHighlightService(),
            collectionService: container.ayahBookmarkCollectionService(),
            readingBookmarkService: container.readingBookmarkService(),
            quran: quran,
            overlayService: overlayService
        )
        var interactorDeps = QuranInteractor.Deps(
            quran: quran,
            overlayService: overlayService,
            ayahMenuBuilder: AyahMenuBuilder(container: container),
            moreMenuBuilder: MoreMenuBuilder(),
            audioBannerBuilder: AudioBannerBuilder(container: container),
            wordPointerBuilder: WordPointerBuilder(container: container),
            contentBuilder: ContentBuilder(container: container, overlayService: overlayService),
            translationsSelectionBuilder: TranslationsListBuilder(container: container),
            translationVerseBuilder: TranslationVerseBuilder(container: container),
            resources: container.readingResources,
            annotationsObserver: annotationsObserver,
            ayahNotesBuilder: AyahNotesBuilder(container: container),
            bookmarkAyahsBuilder: BookmarkAyahsBuilder(container: container),
            noteService: noteService,
            readingBookmarkMenuBuilder: ReadingBookmarkMenuBuilder(container: container)
        )
        #else
        let pageBookmarkService = PageBookmarkService(persistence: container.pageBookmarkPersistence)
        let noteService = container.noteService()
        let annotationsObserver = QuranAnnotationsObserver(
            noteService: noteService,
            quran: quran,
            overlayService: overlayService
        )
        var interactorDeps = QuranInteractor.Deps(
            quran: quran,
            overlayService: overlayService,
            ayahMenuBuilder: AyahMenuBuilder(container: container),
            moreMenuBuilder: MoreMenuBuilder(),
            audioBannerBuilder: AudioBannerBuilder(container: container),
            wordPointerBuilder: WordPointerBuilder(container: container),
            contentBuilder: ContentBuilder(container: container, overlayService: overlayService),
            translationsSelectionBuilder: TranslationsListBuilder(container: container),
            translationVerseBuilder: TranslationVerseBuilder(container: container),
            resources: container.readingResources,
            annotationsObserver: annotationsObserver,
            noteEditorBuilder: NoteEditorBuilder(container: container),
            analytics: container.analytics,
            pageBookmarkService: pageBookmarkService,
            noteService: noteService
        )
        #endif
        interactorDeps.tagAyah = tagAyah
        interactorDeps.audioDownloadsBuilder = AudioDownloadsBuilder(container: container)
        interactorDeps.searchBuilder = SearchBuilder(container: container)
        let interactor = QuranInteractor(deps: interactorDeps, input: input)
        let viewController = QuranViewController(interactor: interactor)
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
    let tagAyah: QuranAyahTagger?
}
