//
//  Reading+PrintName.swift
//  QuranEngine
//

import Localization
import QuranKit

extension Reading {
    /// quran_android's print title without its generic "Mushaf", cut to the word that sets it apart where
    /// the full title would truncate the reader's subtitle on a phone. Nil for prints quran_android lacks.
    func printName(language: Language? = nil) -> String? {
        printNameKey.map { l($0, language: language) }
    }

    private var printNameKey: String? {
        switch self {
        case .madinaColored:
            return "reading.madina-colored.short-name"
        case .hafs_1405:
            return "reading.hafs-1405.short-name"
        case .newMadani:
            return "reading.new-madani.short-name"
        case .tajweed:
            return "reading.tajweed.short-name"
        case .naskh:
            return "reading.naskh.short-name"
        case .shemerly:
            return "reading.shemerly.short-name"
        case .qaloon:
            return "reading.qaloon.short-name"
        case .warsh:
            return "reading.warsh.short-name"
        case .hafs_1421, .hafs_1439, .hafs_1440, .hafs_1441, .indoPak:
            return nil
        }
    }
}
