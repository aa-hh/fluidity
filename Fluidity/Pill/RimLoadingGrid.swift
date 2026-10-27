import FluidityCore
import Foundation

/// Turns the loading grid's state into the fill level the shader draws for each square: 0 dark inside, 1 solid.
nonisolated enum RimLoadingGrid {
    /// One fill level per square, 0...1, in fill order. `now` is on the grid's own clock.
    static func lights(grid: LoadingGrid, at now: Duration, reduced: Bool) -> [Float] {
        let stalledSince = grid.stalledSince(at: now)
        return (0..<LoadingGrid.squareCount).map { index in
            if index < grid.litCount {
                let square = grid.lit[index]
                let age = now - square.at
                switch square.arrival {
                case .flicker:
                    // Solid, dark for the second 100 ms, then solid again.
                    if age < .milliseconds(100) { return 1 }
                    if age < .milliseconds(200) { return 0 }
                    return 1
                case .fade:
                    return age < .milliseconds(130) ? Float(age / .milliseconds(130)) : 1
                }
            }
            // The square that lights next blinks once a second while nothing lights.
            if index == grid.litCount, let since = stalledSince {
                return reduced ? 0.40 : 0.425 - 0.125 * cos(2 * .pi * Float((now - since) / .seconds(1)))
            }
            return 0
        }
    }
}
