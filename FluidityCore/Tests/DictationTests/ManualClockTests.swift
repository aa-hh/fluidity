import FluidityTestSupport
import Testing

private actor Flag {
    var isSet = false
    func set() { isSet = true }
}

// Turns red if ManualClock resumes a sleeper before its deadline, or never resumes it.
@Test func manualClockWakesSleeperAtItsDeadline() async throws {
    let clock = ManualClock()
    let deadline = clock.now.advanced(by: .seconds(2))
    let woke = Flag()
    let sleeper = Task {
        try await clock.sleep(until: deadline)
        await woke.set()
    }

    await clock.advance(by: .seconds(1))
    for _ in 0..<10 { await Task.yield() }
    #expect(await woke.isSet == false)

    await clock.advance(by: .seconds(1))
    try await sleeper.value
    #expect(await woke.isSet)
}
