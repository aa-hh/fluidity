import Foundation
import FluidityCore
import Testing

private func progress(_ step: Int, of stepCount: Int, download: Bool = false, _ downloaded: Double? = nil) -> ModelLoadProgress {
    ModelLoadProgress(step: step, stepCount: stepCount, needsDownload: download, downloaded: downloaded)
}

/// The running load's estimate `t` seconds after it began: 85% of its share of twelfths, on its typical time.
private func estimate(_ share: Int, typical: Double, after t: Double) -> Double {
    0.85 * Double(share) / 12 * (1 - exp(-3 * t / typical))
}

private func close(_ a: Double, _ b: Double, within tolerance: Double = 1e-9) -> Bool {
    abs(a - b) < tolerance
}

@Suite struct LoadingLineTests {
    @Test func eachFinishedLoadCommitsItsShare() {
        // Changing a load's share, the download's 6/12, or the 300 ms ease a finished load's share takes, turns this red.
        var two = LoadingLine(reduceMotion: false)
        two.report(progress(0, of: 2), at: .zero)
        two.report(progress(1, of: 2), at: .zero)
        #expect(close(two.fraction(at: .milliseconds(300)) - estimate(10, typical: 30, after: 0.3), 2.0 / 12))
        two.report(progress(2, of: 2), at: .milliseconds(300))
        #expect(two.fraction(at: .milliseconds(600)) == 1)

        var three = LoadingLine(reduceMotion: false)
        three.report(progress(0, of: 3), at: .zero)
        three.report(progress(1, of: 3), at: .zero)
        #expect(close(three.fraction(at: .milliseconds(300)) - estimate(4, typical: 25, after: 0.3), 2.0 / 12))
        three.report(progress(2, of: 3), at: .milliseconds(300))
        #expect(close(three.fraction(at: .milliseconds(600)) - estimate(6, typical: 30, after: 0.3), 6.0 / 12))
        three.report(progress(3, of: 3), at: .milliseconds(600))
        #expect(three.fraction(at: .milliseconds(900)) == 1)

        var download = LoadingLine(reduceMotion: false)
        download.report(progress(0, of: 2, download: true), at: .zero)
        download.report(progress(1, of: 2, download: true), at: .zero)
        #expect(download.fraction(at: .milliseconds(300)) == 1.0 / 12)
        download.report(progress(1, of: 2, download: true, 0.5), at: .milliseconds(300))
        #expect(close(download.fraction(at: .milliseconds(300)), 1.0 / 12 + 3.0 / 12))
        download.report(progress(1, of: 2, download: true, 1), at: .milliseconds(300))
        #expect(close(download.fraction(at: .milliseconds(300)), 7.0 / 12))
        download.report(progress(2, of: 2, download: true), at: .milliseconds(300))
        #expect(download.fraction(at: .milliseconds(600)) == 1)
    }

    @Test func theThreeLoadDownloadGivesEachLoadItsShare() {
        // Changing the three-load download layout's 1, 2, 6 or 3 twelfths turns this red.
        var line = LoadingLine(reduceMotion: false)
        line.report(progress(0, of: 3, download: true), at: .zero)
        line.report(progress(1, of: 3, download: true), at: .zero)
        #expect(close(line.fraction(at: .milliseconds(300)) - estimate(2, typical: 25, after: 0.3), 1.0 / 12))
        line.report(progress(2, of: 3, download: true), at: .milliseconds(300))
        #expect(close(line.fraction(at: .milliseconds(800)), 3.0 / 12))
        line.report(progress(2, of: 3, download: true, 1), at: .milliseconds(800))
        #expect(close(line.fraction(at: .milliseconds(800)), 9.0 / 12))
        // The speech model's estimate stops at 85% of its 3/12.
        #expect(close(line.fraction(at: .seconds(10_000)), 9.0 / 12 + 0.85 * 3 / 12))
        line.report(progress(3, of: 3, download: true), at: .seconds(10_000))
        #expect(line.fraction(at: .seconds(10_000) + .milliseconds(300)) == 1)
    }

    @Test func theRunningLoadFillsOnItsEstimateUpTo85Percent() {
        // Changing the estimate's curve, its 85% ceiling, or the 1 s, 25 s or 30 s typical times, turns this red.
        var speech = LoadingLine(reduceMotion: false)
        speech.report(progress(0, of: 2), at: .zero)
        speech.report(progress(1, of: 2), at: .zero)
        #expect(close(speech.fraction(at: .seconds(30)) - 2.0 / 12, 10.0 / 12 * 0.85 * (1 - exp(-3)), within: 1e-6))
        #expect(speech.fraction(at: .seconds(10_000)) - 2.0 / 12 <= 10.0 / 12 * 0.85 + 1e-9)

        var voiceDetector = LoadingLine(reduceMotion: false)
        voiceDetector.report(progress(0, of: 2), at: .zero)
        #expect(close(voiceDetector.fraction(at: .seconds(1)), 2.0 / 12 * 0.85 * (1 - exp(-3)), within: 1e-6))

        var wordCheck = LoadingLine(reduceMotion: false)
        wordCheck.report(progress(0, of: 3), at: .zero)
        wordCheck.report(progress(1, of: 3), at: .zero)
        #expect(close(wordCheck.fraction(at: .seconds(25)) - 2.0 / 12, 4.0 / 12 * 0.85 * (1 - exp(-3)), within: 1e-6))
    }

    @Test func aFinishEasesWithNoJump() {
        // Snapping to full when the load ends, or easing over anything but 300 ms, turns this red.
        var line = LoadingLine(reduceMotion: false)
        line.report(progress(0, of: 2), at: .zero)
        line.report(progress(1, of: 2), at: .zero)
        let before = line.fraction(at: .seconds(5))
        line.report(progress(2, of: 2), at: .seconds(5))
        #expect(line.fraction(at: .seconds(5)) == before)
        let midway = line.fraction(at: .seconds(5) + .milliseconds(150))
        #expect(midway > before && midway < 1)
        #expect(line.fraction(at: .seconds(5) + .milliseconds(300)) == 1)
        #expect(!line.isDone(at: .seconds(5) + .milliseconds(290)))
        #expect(line.isDone(at: .seconds(5) + .milliseconds(300)))
        #expect(line.isFinishing)
    }

    @Test func theFillNeverGoesBackwards() {
        // Counting the download's share twice and dropping one at the finish, or restarting a finished load's
        // estimate from zero, so the fill falls back for a moment, turns this red.
        var line = LoadingLine(reduceMotion: false)
        let reports: [(ms: Int, progress: ModelLoadProgress)] = [
            (0, progress(0, of: 2, download: true)),
            (500, progress(1, of: 2, download: true, 0)),
            (1000, progress(1, of: 2, download: true, 0.4)),
            (1200, progress(1, of: 2, download: true, 1)),
            (1250, progress(2, of: 2, download: true)),
        ]
        var previous = 0.0
        for ms in stride(from: 0, through: 3000, by: 10) {
            for report in reports where report.ms == ms { line.report(report.progress, at: .milliseconds(ms)) }
            let value = line.fraction(at: .milliseconds(ms))
            #expect(value >= previous, "fell back at \(ms) ms")
            previous = value
        }
    }

    @Test func reduceMotionChangesAtMostTwiceASecondWithA130MillisecondFade() {
        // Sampling more often than every 500 ms under Reduce Motion, or fading to a sample over anything but
        // 130 ms, turns this red.
        var line = LoadingLine(reduceMotion: true)
        line.report(progress(0, of: 2), at: .zero)
        line.report(progress(1, of: 2), at: .zero)
        for ms in [0, 200, 490] {
            line.update(at: .milliseconds(ms))
            #expect(line.fraction(at: .milliseconds(ms)) == 0)
        }
        line.update(at: .milliseconds(500))
        #expect(line.fraction(at: .milliseconds(500)) == 0)
        // The step-1 ease ended at 300 ms, so the sample is 2/12 plus the speech model's estimate.
        let sample = 2.0 / 12 + estimate(10, typical: 30, after: 0.5)
        #expect(close(line.fraction(at: .milliseconds(565)), sample / 2))
        #expect(close(line.fraction(at: .milliseconds(630)), sample))
        let held = line.fraction(at: .milliseconds(800))
        line.update(at: .milliseconds(800))
        #expect(line.fraction(at: .milliseconds(800)) == held)
    }

    @Test func aLoadThatEndsWithoutFinishingShowsAFullLineAtOnce() {
        // Keeping a failed load's line, so the pill stays part filled after the load gave up, turns this red.
        var line: LoadingLine? = LoadingLine(reduceMotion: false)
        line?.report(progress(0, of: 2), at: .zero)
        #expect(LoadingLine.step(&line, isModelLoading: true, at: .seconds(1)) < 1)
        #expect(LoadingLine.step(&line, isModelLoading: false, at: .seconds(1)) == 1)
        #expect(line == nil)
    }

    @Test func aFinishingLoadKeepsItsLineUntilFullThenDropsIt() {
        // Dropping the line when the load ends instead of once it has eased to full, or keeping it after, turns this red.
        var line: LoadingLine? = LoadingLine(reduceMotion: false)
        line?.report(progress(0, of: 2), at: .zero)
        line?.report(progress(1, of: 2), at: .zero)
        line?.report(progress(2, of: 2), at: .seconds(5))
        #expect(LoadingLine.step(&line, isModelLoading: false, at: .seconds(5) + .milliseconds(150)) < 1)
        #expect(line != nil)
        #expect(LoadingLine.step(&line, isModelLoading: false, at: .seconds(5) + .milliseconds(300)) == 1)
        #expect(line == nil)
    }

    @Test(arguments: [(true, 0.0), (false, 1.0)])
    func withNoLineTheFillFollowsWhetherTheModelIsLoading(isModelLoading: Bool, fill: Double) {
        // Swapping the empty fill while loading and the full one otherwise, when no report has come, turns this red.
        var line: LoadingLine?
        #expect(LoadingLine.step(&line, isModelLoading: isModelLoading, at: .zero) == fill)
    }

    @Test func theDownloadLayoutsEstimateWaitsForTheDownload() {
        // Starting the speech model's estimate before its download ends turns this red.
        var line = LoadingLine(reduceMotion: false)
        line.report(progress(1, of: 2, download: true, 0.5), at: .zero)
        #expect(line.fraction(at: .seconds(20)) == 1.0 / 12 + 3.0 / 12)
        line.report(progress(1, of: 2, download: true, 1), at: .seconds(20))
        #expect(line.fraction(at: .seconds(50)) > 1.0 / 12 + 6.0 / 12)
    }
}
