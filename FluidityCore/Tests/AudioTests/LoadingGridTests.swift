import FluidityCore
import Testing

private func progress(_ step: Int, of stepCount: Int, download: Bool = false, _ downloaded: Double? = nil) -> ModelLoadProgress {
    ModelLoadProgress(step: step, stepCount: stepCount, needsDownload: download, downloaded: downloaded)
}

@Suite struct LoadingGridTests {
    @Test func eachFinishedLoadLightsItsShare() {
        // Giving a load the wrong number of squares, so its end lights more or fewer than its share, turns this red.
        var two = LoadingGrid(reduceMotion: false)
        two.report(progress(0, of: 2), at: .zero)
        two.report(progress(1, of: 2), at: .zero)
        two.update(at: .milliseconds(300))
        #expect(two.litCount == 4)
        two.report(progress(2, of: 2), at: .milliseconds(300))
        two.update(at: .seconds(10))
        #expect(two.litCount == 32)

        var three = LoadingGrid(reduceMotion: false)
        three.report(progress(0, of: 3), at: .zero)
        three.report(progress(1, of: 3), at: .zero)
        three.update(at: .milliseconds(300))
        #expect(three.litCount == 4)
        three.report(progress(2, of: 3), at: .milliseconds(300))
        three.update(at: .milliseconds(800))
        #expect(three.litCount == 4 + 12)
        three.report(progress(3, of: 3), at: .milliseconds(800))
        three.update(at: .seconds(10))
        #expect(three.litCount == 32)

        var download = LoadingGrid(reduceMotion: false)
        download.report(progress(0, of: 2, download: true), at: .zero)
        download.report(progress(1, of: 2, download: true), at: .zero)
        download.update(at: .milliseconds(100))
        #expect(download.litCount == 2)
        download.report(progress(1, of: 2, download: true, 1), at: .milliseconds(100))
        #expect(download.litCount == 2 + 16)
        download.update(at: .milliseconds(200))
        #expect(download.litCount == 2 + 16)
        download.report(progress(2, of: 2, download: true), at: .milliseconds(200))
        download.update(at: .seconds(10))
        #expect(download.litCount == 32)
    }

    @Test func theThreeLoadDownloadGivesEachLoadItsShare() {
        // Changing the three-load download layout's 2, 6, 16 or 8 squares turns this red.
        var grid = LoadingGrid(reduceMotion: false)
        grid.report(progress(0, of: 3, download: true), at: .zero)
        grid.report(progress(1, of: 3, download: true), at: .zero)
        grid.update(at: .milliseconds(300))
        #expect(grid.litCount == 2)
        grid.report(progress(2, of: 3, download: true), at: .milliseconds(300))
        grid.update(at: .milliseconds(800))
        #expect(grid.litCount == 2 + 6)
        grid.report(progress(2, of: 3, download: true, 1), at: .milliseconds(800))
        #expect(grid.litCount == 2 + 6 + 16)
        // The speech model's estimate stops at floor(0.85 × 8) = 6 of its 8 squares.
        grid.update(at: .seconds(10_000))
        #expect(grid.litCount == 2 + 6 + 16 + 6)
        grid.report(progress(3, of: 3, download: true), at: .seconds(10_000))
        grid.update(at: .seconds(10_001))
        #expect(grid.litCount == 2 + 6 + 16 + 8)
    }

    @Test func theWordCheckEstimateRunsOn25Seconds() {
        // Changing the word check's typical time from 25 s turns this red.
        var grid = LoadingGrid(reduceMotion: false)
        grid.report(progress(0, of: 3), at: .zero)
        grid.report(progress(1, of: 3), at: .zero)
        grid.update(at: .seconds(6))
        // 4 + floor(0.85 × 12 × (1 − e^(−3 × 6 ÷ 25))) = 4 + floor(5.24); 20 s would give 6 and 30 s 4.
        #expect(grid.litCount == 4 + 5)
    }

    @Test func theVoiceDetectorEstimateRunsOn1Second() {
        // Changing the voice detector's typical time from 1 s turns this red.
        var grid = LoadingGrid(reduceMotion: false)
        grid.report(progress(0, of: 2), at: .zero)
        grid.update(at: .milliseconds(500))
        // floor(0.85 × 4 × (1 − e^(−3 × 0.5 ÷ 1))) = floor(2.64); 0.5 s would give 3 and 2 s 1.
        #expect(grid.litCount == 2)
    }

    @Test func theRunningLoadFillsOnItsEstimateUpTo85Percent() {
        // Changing the estimate's curve, or letting it light the running load's last squares on its own, turns this red.
        var grid = LoadingGrid(reduceMotion: false)
        grid.report(progress(0, of: 2), at: .zero)
        grid.report(progress(1, of: 2), at: .seconds(1))
        grid.update(at: .seconds(11))
        #expect(grid.litCount == 4 + 15)
        grid.update(at: .seconds(301))
        #expect(grid.litCount == 4 + 23)
        grid.update(at: .seconds(10_000))
        #expect(grid.litCount == 4 + 23)
    }

    @Test func theEndLightsTheRestOneEvery40Milliseconds() {
        // Lighting the remaining squares all at once, at another spacing, or ending the grid before the 260 ms hold,
        // turns this red.
        var grid = LoadingGrid(reduceMotion: false)
        grid.report(progress(0, of: 2), at: .zero)
        grid.report(progress(1, of: 2), at: .seconds(1))
        grid.update(at: .seconds(11))
        let remaining = 32 - grid.litCount
        grid.report(progress(2, of: 2), at: .seconds(11))
        #expect(grid.isFinishing)
        let allLitAt = Duration.seconds(11) + .milliseconds(40) * (remaining - 1)
        #expect(grid.allLitAt == allLitAt)
        grid.update(at: allLitAt)
        #expect(grid.lit.suffix(remaining).map { $0.at } == (0..<remaining).map { Duration.seconds(11) + .milliseconds(40) * $0 })
        #expect(!grid.isDone(at: allLitAt + .milliseconds(259)))
        #expect(grid.isDone(at: allLitAt + .milliseconds(260)))
    }

    @Test func onlyOneSquareASecondFlickers() {
        // Flickering every arrival, or never flickering again after the first, turns this red.
        var grid = LoadingGrid(reduceMotion: false)
        grid.report(progress(0, of: 2), at: .zero)
        grid.report(progress(1, of: 2), at: .zero)
        grid.report(progress(2, of: 2), at: .seconds(1))
        grid.update(at: .seconds(5))
        #expect(grid.lit[0].arrival == .flicker)
        #expect(grid.lit[1].at == .milliseconds(40))
        #expect(grid.lit[1].arrival == .fade)
        #expect(grid.lit.filter { $0.at > .zero && $0.at < .seconds(1) }.allSatisfy { $0.arrival == .fade })
        #expect(grid.lit.first { $0.at == .seconds(1) }?.arrival == .flicker)
        #expect(grid.lit.first { $0.at == .seconds(1) + .milliseconds(40) }?.arrival == .fade)
    }

    @Test(arguments: [false, true])
    func theGridStallsAfterASecondWithNothingLit(_ reduceMotion: Bool) throws {
        // Reporting a stall sooner than a second after the last square, at another time, or after the end, turns this red.
        var grid = LoadingGrid(reduceMotion: reduceMotion)
        grid.report(progress(0, of: 2), at: .zero)
        grid.report(progress(1, of: 2), at: .seconds(1))
        grid.update(at: .seconds(301))
        let last = try #require(grid.lit.last?.at)
        #expect(grid.stalledSince(at: last + .milliseconds(999)) == nil)
        #expect(grid.stalledSince(at: last + .seconds(1)) == last + .seconds(1))
        #expect(grid.stalledSince(at: .seconds(301)) == last + .seconds(1))
        grid.report(progress(2, of: 2), at: .seconds(301))
        #expect(grid.stalledSince(at: .seconds(400)) == nil)
    }

    @Test func theDownloadFillsHalfTheGridAndNeverDrains() {
        // Lighting download squares from a report for an earlier load, dropping squares when the fraction falls, or
        // starting the speech model's estimate before its download ends, turns this red.
        var grid = LoadingGrid(reduceMotion: false)
        grid.report(progress(0, of: 2, download: true, 0.9), at: .zero)
        grid.report(progress(1, of: 2, download: true, 0), at: .zero)
        grid.update(at: .milliseconds(100))
        #expect(grid.litCount == 2)
        grid.report(progress(1, of: 2, download: true, 0.5), at: .seconds(1))
        #expect(grid.litCount == 2 + 8)
        grid.report(progress(1, of: 2, download: true, 0.4), at: .seconds(2))
        #expect(grid.litCount == 2 + 8)
        grid.update(at: .seconds(100))
        #expect(grid.litCount == 2 + 8)
        grid.report(progress(1, of: 2, download: true, 1), at: .seconds(100))
        #expect(grid.litCount == 2 + 16)
        grid.update(at: .seconds(100) + .milliseconds(500))
        #expect(grid.litCount == 2 + 16)
        grid.update(at: .seconds(101))
        #expect(grid.litCount == 2 + 16 + 1)
    }

    @Test func reduceMotionFadesEveryArrivalAndEndsAtOnce() {
        // Flickering under Reduce Motion, spacing its end out, or adding download squares more often than every
        // 500 ms, turns this red.
        var grid = LoadingGrid(reduceMotion: true)
        grid.report(progress(0, of: 2, download: true), at: .zero)
        grid.report(progress(1, of: 2, download: true, 0.25), at: .seconds(1))
        #expect(grid.litCount == 2 + 4)
        grid.report(progress(1, of: 2, download: true, 0.5), at: .seconds(1) + .milliseconds(100))
        #expect(grid.litCount == 2 + 4)
        grid.update(at: .seconds(1) + .milliseconds(499))
        #expect(grid.litCount == 2 + 4)
        grid.update(at: .seconds(2))
        #expect(grid.litCount == 2 + 8)
        #expect(grid.lit.suffix(4).allSatisfy { $0.at == .seconds(1) + .milliseconds(500) })

        grid.report(progress(2, of: 2, download: true), at: .seconds(5))
        #expect(grid.litCount == 32)
        #expect(grid.allLitAt == .seconds(5))
        #expect(grid.lit.suffix(32 - 10).allSatisfy { $0.at == .seconds(5) })
        #expect(grid.lit.allSatisfy { $0.arrival == .fade })
    }
}
