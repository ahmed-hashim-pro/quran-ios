//
//  AudioDownloadsBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AppDependencies
import Foundation
import QuranAudioKit
import ReadingService
import ReciterService
import SystemDependencies
import UIKit

@MainActor
public struct AudioDownloadsBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build() -> UIViewController {
        let downloader = QuranAudioDownloader(
            baseURL: container.filesAppHost,
            downloader: container.downloadManager
        )
        let sizeInfoRetriever = ReciterSizeInfoRetriever(baseURL: container.filesAppHost)
        let viewModel = AudioDownloadsViewModel(
            analytics: container.analytics,
            deleter: ReciterAudioDeleter(),
            ayahsDownloader: downloader,
            sizeInfoRetriever: sizeInfoRetriever,
            recitersRetriever: ReciterDataRetriever()
        )
        let viewController = AudioDownloadsViewController(viewModel: viewModel)
        viewModel.showSuras = { [weak viewController, container] reciter in
            let suras = ReciterSurasViewModel(
                files: SuraAudioFiles(reciter: reciter, baseURL: container.filesAppHost) { FileManager.default.fileExists(atPath: $0.path) },
                quran: ReadingPreferences.shared.reading.quran,
                downloader: downloader,
                fileSystem: DefaultFileSystem()
            )
            viewController?.navigationController?.pushViewController(ReciterSurasViewController(viewModel: suras), animated: true)
        }
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
