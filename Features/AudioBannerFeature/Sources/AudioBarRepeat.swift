import QuranAudio

extension Runs {
    /// quran_android's audio bar cycles one play, then one to three repeats, then a loop, and back.
    var nextAudioBarRepeat: Runs {
        switch self {
        case .finite(let count) where count < 4: .finite(count + 1)
        case .finite(4): .indefinite
        default: .finite(1)
        }
    }
}
