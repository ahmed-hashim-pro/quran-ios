//
//  WordFrameLineRepair.swift
//
//  Part of the my-stream fork.
//

import CoreGraphics
import QuranGeometry

/// quran_android's Madinah Colored print draws its first two pages (Al-Fatihah and the start of Al-Baqarah) from one box
/// per piece of a verse, and numbers the pieces of each verse in `line_number` instead of numbering the page's lines. The
/// processor groups frames by line, so the first piece of every verse landed in "line 1" and was stretched into one
/// block, and a tap or a highlight covered several verses. This gives such frames the line they sit on.
struct WordFrameLineRepair {
    /// A line whose frames are spread over more than this many frame heights is not one line.
    private static let tolerance: CGFloat = 2
    /// A frame whose centre is farther than this many frame heights from its line's first frame starts a new line.
    private static let newLineAfter: CGFloat = 0.6

    func repaired(_ frames: [WordFrame]) -> [WordFrame] {
        needsRepair(frames) ? renumbered(frames) : frames
    }

    private func needsRepair(_ frames: [WordFrame]) -> Bool {
        let height = medianHeight(frames)
        guard height > 0 else { return false }
        return Dictionary(grouping: frames, by: \.line).values.contains { line in
            let centres = line.map(Self.centre)
            return (centres.max()! - centres.min()!) > height * Self.tolerance
        }
    }

    private func renumbered(_ frames: [WordFrame]) -> [WordFrame] {
        let limit = medianHeight(frames) * Self.newLineAfter
        var lineOf: [Int: Int] = [:]
        var line = 0
        var anchor = -CGFloat.infinity
        for index in frames.indices.sorted(by: { Self.centre(frames[$0]) < Self.centre(frames[$1]) }) {
            let centre = Self.centre(frames[index])
            if centre - anchor > limit {
                line += 1
                anchor = centre
            }
            lineOf[index] = line
        }
        return frames.enumerated().map { index, frame in
            WordFrame(line: lineOf[index]!, word: frame.word, minX: frame.minX, maxX: frame.maxX, minY: frame.minY, maxY: frame.maxY)
        }
    }

    private func medianHeight(_ frames: [WordFrame]) -> CGFloat {
        let heights = frames.map { CGFloat($0.maxY - $0.minY) }.sorted()
        return heights.isEmpty ? 0 : heights[heights.count / 2]
    }

    private static func centre(_ frame: WordFrame) -> CGFloat {
        CGFloat(frame.minY + frame.maxY) / 2
    }
}
