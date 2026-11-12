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
import TranslationService
import TranslationsFeature
import TranslationVerseFeature
import UIKit
import WordPointerFeature

/// Tags `ayah` in the app's own bookmark tags, presenting from `presenter`.
public typealias QuranAyahTagger = @MainActor (_ ayah: AyahNumber, _ presenter: UIViewController) -> Void

/// Lets the user pick another print, presenting from `presenter`; `page` is the one being read.
public typealias QuranPrintChooser = @MainActor (_ page: Page, _ presenter: UIViewController) -> Void

/// Opens the app's own import and export of bookmarks, quran_android's Advanced Options, from `presenter`.
public typealias QuranAdvancedOptionsOpener = @MainActor (_ presenter: UIViewController) -> Void

@MainActor
public struct QuranBuilder {
    // MARK: Lifecycle

    /// The ayah menu offers quran_android's Tag only when `tagAyah` is given, the More menu a print
    /// choice only when `choosePrint` is, and the reader's settings Advanced Options only when
    /// `openAdvancedOptions` is.
    public init(
        container: AppDependencies,
        tagAyah: QuranAyahTagger? = nil,
        choosePrint: QuranPrintChooser? = nil,
        openAdvancedOptions: QuranAdvancedOptionsOpener? = nil
    ) {
        self.container = container
        self.tagAyah = tagAyah
        self.choosePrint = choosePrint
        self.openAdvancedOptions = openAdvancedOptions
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
        interactorDeps.choosePrint = choosePrint
        interactorDeps.openAdvancedOptions = openAdvancedOptions
        interactorDeps.audioDownloadsBuilder = AudioDownloadsBuilder(container: container)
        interactorDeps.searchBuilder = SearchBuilder(container: container)
        interactorDeps.localTranslationsRetriever = LocalTranslationsRetriever(databasesURL: container.databasesURL)
        let interactor = QuranInteractor(deps: interactorDeps, input: input)
        let viewController = QuranViewController(interactor: interactor)
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
    let tagAyah: QuranAyahTagger?
    let choosePrint: QuranPrintChooser?
    let openAdvancedOptions: QuranAdvancedOptionsOpener?
}
