//
//  QuranPageMushaf.swift
//

public enum QuranPageMushaf: Int16, Sendable {
    case madani1405 = 0
    case madani1440 = 1
    case indoPak = 2
    // quran_android's prints. Stored with bookmarks, so they sit far from upstream's numbers.
    case newMadani = 101
    case naskh = 102
    case shemerly = 103
    case qaloonWarsh = 104

    // MARK: Public

    public var quran: Quran {
        switch self {
        case .madani1405:
            .hafsMadani1405
        case .madani1440:
            .hafsMadani1440
        case .indoPak:
            .hafsIndoPak
        case .newMadani:
            .hafsNewMadani
        case .naskh:
            .hafsNaskh
        case .shemerly:
            .hafsShemerly
        case .qaloonWarsh:
            .qaloonWarsh
        }
    }
}
