//
//  AudioPlaying.swift
//  QueuePlayer
//
//  Created by Afifi, Mohamed on 4/27/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation
import QuranAudio

struct FramePlaying {
    var frameIndex: Int
    var framePlays: Int
}

struct FilePlaying {
    // MARK: Internal

    let fileIndex: Int
}

struct AudioPlaying {
    // MARK: Lifecycle

    init(request: AudioRequest, fileIndex: Int, frameIndex: Int) {
        self.request = request
        filePlaying = FilePlaying(fileIndex: fileIndex)
        framePlaying = FramePlaying(frameIndex: frameIndex, framePlays: 0)
        requestPlays = 0
    }

    // MARK: Internal

    private(set) var request: AudioRequest
    private(set) var filePlaying: FilePlaying
    private(set) var framePlaying: FramePlaying
    var requestPlays: Int

    var file: AudioFile {
        request.files[filePlaying.fileIndex]
    }

    var frame: AudioFrame {
        file.frames[framePlaying.frameIndex]
    }

    var frameEndTime: TimeInterval? {
        if let frameEndTime = request.files[filePlaying.fileIndex].frames[framePlaying.frameIndex].endTime {
            return frameEndTime
        }

        guard let nextFrame = nextFrame() else {
            // last frame
            return request.endTime
        }
        if nextFrame.fileIndex == filePlaying.fileIndex {
            // same file
            return request.files[nextFrame.fileIndex].frames[nextFrame.frameIndex].startTime
        }
        // different file
        return nil
    }

    /// Keeps the plays counted so far, so the playing frame stops at the new count if it already reached it.
    mutating func setFrameRuns(_ runs: Runs) {
        request = request.withFrameRuns(runs)
    }

    /// Keeps the plays counted so far, as `setFrameRuns` does, for the range's runs too.
    mutating func setRepeats(frameRuns: Runs, requestRuns: Runs, verseDelay: VerseDelay, repetitionDelay: RepetitionDelay) {
        request = request.withRepeats(
            frameRuns: frameRuns,
            requestRuns: requestRuns,
            verseDelay: verseDelay,
            repetitionDelay: repetitionDelay
        )
    }

    mutating func setPlaying(fileIndex: Int, frameIndex: Int) {
        filePlaying = FilePlaying(fileIndex: fileIndex)
        framePlaying.frameIndex = frameIndex
    }

    func isLastPlayForCurrentFrame() -> Bool {
        framePlaying.framePlays + 1 >= request.frameRuns.maxRuns
    }

    func isLastRun() -> Bool {
        requestPlays + 1 >= request.requestRuns.maxRuns
    }

    mutating func incrementRequestPlays() {
        guard request.requestRuns != .indefinite else {
            return
        }
        requestPlays += 1
    }

    mutating func incrementFramePlays() {
        guard request.frameRuns != .indefinite else {
            return
        }
        framePlaying.framePlays += 1
    }

    mutating func resetFramePlays() {
        framePlaying.framePlays = 0
    }

    func previousFrame() -> (fileIndex: Int, frameIndex: Int)? {
        // same file
        if framePlaying.frameIndex > 0 {
            return (filePlaying.fileIndex, framePlaying.frameIndex - 1)
        }
        // previous file
        if filePlaying.fileIndex > 0 {
            let previousFileIndex = filePlaying.fileIndex - 1
            return (previousFileIndex, request.files[previousFileIndex].frames.count - 1)
        }
        // first frame
        return nil
    }

    func nextFrame() -> (fileIndex: Int, frameIndex: Int)? {
        // same file
        if framePlaying.frameIndex < file.frames.count - 1 {
            return (filePlaying.fileIndex, framePlaying.frameIndex + 1)
        }
        // next file
        if filePlaying.fileIndex < request.files.count - 1 {
            return (filePlaying.fileIndex + 1, 0)
        }
        // last frame
        return nil
    }
}
