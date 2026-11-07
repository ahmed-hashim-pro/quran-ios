import QuranAudio
import QuranKit
import Utilities
import XCTest
@testable import AudioDownloadsFeature

final class SuraAudioFilesTests: XCTestCase {
    // MARK: Internal

    func testAGappedSurahIsDownloadedOnceEveryAyahIs() {
        let baqarah = quran.suras[1]
        var present = Set(baqarah.verses.map { gapped.localURL(ayah: $0).path })
        XCTAssertTrue(files(gapped, present).isDownloaded(baqarah))
        present.remove(gapped.localURL(ayah: baqarah.lastVerse).path)
        XCTAssertFalse(files(gapped, present).isDownloaded(baqarah))
    }

    func testAGaplessSurahIsOneFileAndIgnoresTheDatabase() {
        let kahf = quran.suras[17]
        let audio = files(gapless, [gapless.localURL(sura: kahf).path])
        XCTAssertTrue(audio.isDownloaded(kahf))
        XCTAssertEqual(audio.downloadedSuras(in: quran), [kahf])
    }

    func testDeletingKeepsWhatOtherSurahsShare() {
        let fatihah = quran.suras[0]
        let deletable = files(gapped, []).deletableFiles(of: fatihah)
        XCTAssertFalse(deletable.contains(gapped.localURL(ayah: quran.firstVerse)), "the basmala serves every gapped surah")
        XCTAssertEqual(deletable.count, fatihah.verses.count - 1)
        XCTAssertEqual(files(gapless, []).deletableFiles(of: fatihah), [gapless.localURL(sura: fatihah)])
    }

    func testFindsTheSurahADownloadIsFor() {
        let baqarah = quran.suras[1]
        let audio = files(gapped, [])
        let basmala = gapped.localURL(ayah: quran.firstVerse)
        let ayahs = baqarah.verses.prefix(3).map { gapped.localURL(ayah: $0) }
        XCTAssertEqual(audio.sura(downloadingTo: [basmala] + ayahs, in: quran), baqarah)
        XCTAssertEqual(audio.sura(downloadingTo: [basmala], in: quran), quran.suras[0])
        let wholeReciter = quran.suras.prefix(3).map { gapped.localURL(ayah: $0.firstVerse) }
        XCTAssertNil(audio.sura(downloadingTo: wholeReciter, in: quran), "a download of many surahs is not one surah's")
        XCTAssertNil(audio.sura(downloadingTo: [gapless.localURL(sura: baqarah)], in: quran), "another reciter's download")
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405
    private let gapped = Reciter(id: 1, nameKey: "gapped", directory: "gapped", audioURL: URL(string: "https://example.com/gapped/")!, audioType: .gapped, hasGaplessAlternative: false, category: .arabic)
    private let gapless = Reciter(id: 2, nameKey: "gapless", directory: "gapless", audioURL: URL(string: "https://example.com/gapless/")!, audioType: .gapless(databaseName: "timing"), hasGaplessAlternative: false, category: .arabic)

    private func files(_ reciter: Reciter, _ present: Set<String>) -> SuraAudioFiles {
        let root = FileManager.documentsURL.path
        return SuraAudioFiles(reciter: reciter, baseURL: URL(string: "https://example.com/")!) { url in
            present.contains(String(url.path.dropFirst(root.count + 1)))
        }
    }
}
