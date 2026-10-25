// AA-305 spike: measure live-words approaches with FluidAudio on real recordings.
// Prints and writes numbers only, never transcript text.
//
// Usage: LiveWordsSpike <mode> <clip-list> <out.jsonl> [model-dir]
//   a        re-run TDT v2 on the growing recording ~1/s; one AsrManager for preview and final
//   b160     Parakeet EOU 160 ms streaming live, TDT v2 final
//   b320     Parakeet EOU 320 ms streaming live, TDT v2 final
//   ab160 / ab320  both live loops at once; separate AsrManagers for preview and final
//   boost    TDT v2 final only (no live words) plus vocabulary boosting
//   stress   concurrent transcribes on one AsrManager vs two
//   load     model load times (pass a copied model dir as arg 4 for a cold load)
// Clip list: one "<seconds> <path>" per line. Audio is fed in 100 ms buffers at real-time pace.

import AVFoundation
import FluidAudio
import Foundation

let args = CommandLine.arguments
let mode = args[1]
let clips: [String] = (try? String(contentsOfFile: args[2], encoding: .utf8))?
    .split(separator: "\n").compactMap { $0.split(separator: " ", maxSplits: 1).last.map(String.init) } ?? []
let outURL = URL(fileURLWithPath: args[3])
FileManager.default.createFile(atPath: outURL.path, contents: nil)
let out = try FileHandle(forWritingTo: outURL)

func now() -> Double { Double(DispatchTime.now().uptimeNanoseconds) / 1e9 }
func sleepUntil(_ t: Double) async {
    let d = t - now()
    if d > 0 { try? await Task.sleep(nanoseconds: UInt64(d * 1e9)) }
}
func peakMB() -> Double { var u = rusage(); getrusage(RUSAGE_SELF, &u); return Double(u.ru_maxrss) / 1_048_576 }
func footprintMB() -> Double {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
    let kr = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count) }
    }
    return kr == KERN_SUCCESS ? Double(info.phys_footprint) / 1_048_576 : -1
}
func emit(_ obj: [String: Any]) {
    let data = try! JSONSerialization.data(withJSONObject: obj)
    out.write(data); out.write("\n".data(using: .utf8)!)
}

func words(_ s: String) -> [String] {
    s.lowercased().split(whereSeparator: { $0.isWhitespace }).map { w in
        String(w.filter { $0.isLetter || $0.isNumber || $0 == "'" })
    }.filter { !$0.isEmpty }
}
/// Word-level edit distance (substitutions + insertions + deletions).
func edits(_ ref: [String], _ hyp: [String]) -> Int {
    if ref.isEmpty { return hyp.count }
    var prev = Array(0...hyp.count)
    for i in 1...ref.count {
        var cur = [i] + Array(repeating: 0, count: hyp.count)
        for j in stride(from: 1, through: hyp.count, by: 1) {
            cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ref[i - 1] == hyp[j - 1] ? 0 : 1))
        }
        prev = cur
    }
    return prev[hyp.count]
}
/// Words already shown that the next update no longer shows in the same place.
func rewritten(_ prev: [String], _ cur: [String]) -> Int {
    var k = 0
    while k < prev.count, k < cur.count, prev[k] == cur[k] { k += 1 }
    return prev.count - k
}
func flicker(_ texts: [String]) -> (updates: Int, events: Int, words: Int) {
    var events = 0, total = 0
    var prev: [String] = []
    var updates = 0
    for t in texts {
        let w = words(t)
        if w == prev { continue }
        updates += 1
        let r = rewritten(prev, w)
        if r > 0 { events += 1; total += r }
        prev = w
    }
    return (updates, events, total)
}

final class Shared: @unchecked Sendable {
    private let lock = NSLock()
    private var samples: [Float] = []
    private var partials: [(Double, String)] = []
    private var _released = false
    private var _inFlight = false
    func append(_ s: ArraySlice<Float>) { lock.lock(); samples.append(contentsOf: s); lock.unlock() }
    func snapshot() -> [Float] { lock.lock(); defer { lock.unlock() }; return samples }
    func addPartial(_ t: Double, _ s: String) { lock.lock(); partials.append((t, s)); lock.unlock() }
    func allPartials() -> [(Double, String)] { lock.lock(); defer { lock.unlock() }; return partials }
    var released: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _released }
        set { lock.lock(); _released = newValue; lock.unlock() }
    }
    var inFlight: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _inFlight }
        set { lock.lock(); _inFlight = newValue; lock.unlock() }
    }
}

struct Pass { let sched, start, end, audioSec: Double; let text: String }

let fmt16k = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
func pcm(_ s: [Float]) -> AVAudioPCMBuffer {
    let b = AVAudioPCMBuffer(pcmFormat: fmt16k, frameCapacity: AVAudioFrameCount(s.count))!
    b.frameLength = AVAudioFrameCount(s.count)
    s.withUnsafeBufferPointer { b.floatChannelData![0].update(from: $0.baseAddress!, count: s.count) }
    return b
}

let converter = AudioConverter()
func load(_ path: String) throws -> [Float] { try converter.resampleAudioFile(path: path) }
/// First 100 ms frame louder than a fifth of the clip's 90th-percentile frame level.
func onsetSec(_ a: [Float]) -> Double {
    let rms = stride(from: 0, to: a.count, by: 1600).map { i -> Float in
        let f = a[i..<min(a.count, i + 1600)]
        return (f.reduce(0) { $0 + $1 * $1 } / Float(f.count)).squareRoot()
    }
    let p90 = rms.sorted()[Int(Double(rms.count - 1) * 0.9)]
    let th = max(0.005, p90 * 0.2)
    return Double(rms.firstIndex { $0 > th } ?? 0) * 0.1
}

// MARK: - Model loading

func timed<T>(_ f: () async throws -> T) async rethrows -> (T, Double) {
    let s = now(); let r = try await f(); return (r, now() - s)
}

if mode == "load" {
    var row: [String: Any] = ["mode": "load"]
    if args.count > 4 {
        // Cold: load from a freshly copied directory the Neural Engine has never seen.
        let dir = URL(fileURLWithPath: args[4])
        let (_, t) = try await timed { try await AsrModels.load(from: dir, version: .v2) }
        row["tdtLoadFromDirSec"] = t
    } else {
        let (_, t1) = try await timed { try await AsrModels.downloadAndLoad(version: .v2) }
        row["tdtLoadSec"] = t1
        let (_, t2) = try await timed { try await CtcModels.downloadAndLoad() }
        row["ctcLoadSec"] = t2
        for size in [StreamingChunkSize.ms160, .ms320] {
            let m = StreamingEouAsrManager(chunkSize: size)
            let (_, t) = try await timed { try await m.loadModels() }
            row["eou\(size.durationMs)LoadSec"] = t
        }
    }
    row["peakMB"] = peakMB()
    emit(row); print(row); exit(0)
}

let (models, tdtLoad) = try await timed { try await AsrModels.downloadAndLoad(version: .v2) }
let afterTdt = footprintMB()
let finalMgr = AsrManager(config: .default, models: models)
let layers = await finalMgr.decoderLayerCount
func tdt(_ m: AsrManager, _ s: [Float]) async throws -> ASRResult {
    var st = TdtDecoderState.make(decoderLayers: layers)
    return try await m.transcribe(s, decoderState: &st)
}
// Warm up so the first clip is not charged with first-run costs.
_ = try await tdt(finalMgr, [Float](repeating: 0.001, count: 16000))
print("tdt loaded in \(String(format: "%.2f", tdtLoad)) s, footprint \(Int(afterTdt)) MB")
emit(["mode": mode, "kind": "setup", "tdtLoadSec": tdtLoad, "footprintAfterTdtMB": afterTdt])

// MARK: - Stress: concurrent transcribes

if mode == "stress" {
    let sample = try load(clips[min(15, clips.count - 1)])
    let solo = try await tdt(finalMgr, sample).text
    let second = AsrManager(config: .default, models: models)
    for (label, mgrB) in [("oneManager", finalMgr), ("twoManagers", second)] {
        var mismatches = 0, errors = 0
        let s = now()
        for _ in 0..<50 {
            await withTaskGroup(of: String?.self) { g in
                g.addTask { try? await tdt(finalMgr, sample).text }
                g.addTask { try? await tdt(mgrB, sample).text }
                for await r in g {
                    if let r { if r != solo { mismatches += 1 } } else { errors += 1 }
                }
            }
        }
        let row: [String: Any] = ["mode": "stress", "setup": label, "pairs": 50, "mismatches": mismatches,
                                  "errors": errors, "sec": now() - s, "clipSec": Double(sample.count) / 16000]
        emit(row); print(row)
    }
    exit(0)
}

// MARK: - Boost: final pass without live words, plus vocabulary boosting

if mode == "boost" {
    let before = footprintMB()
    let (ctc, ctcLoad) = try await timed { try await CtcModels.downloadAndLoad() }
    let terms = ["Fluidity", "Parakeet", "Kubernetes", "Zendesk", "Okonkwo", "Siobhan", "Nguyen", "Figma",
                 "Supabase", "PostHog", "Cloudflare", "Tailscale", "Obsidian", "Raycast", "Anthropic",
                 "SwiftUI", "Grafana", "Terraform", "Dvořák", "Mailchimp"]
    let (session, sessionInit) = try await timed {
        try await VocabularyBoostingSession(
            vocabulary: CustomVocabularyContext(terms: terms.map { CustomVocabularyTerm(text: $0) }), ctcModels: ctc)
    }
    let afterCtc = footprintMB()
    emit(["mode": "boost", "kind": "setup", "ctcLoadSec": ctcLoad, "sessionInitSec": sessionInit,
          "ctcExtraFootprintMB": afterCtc - before, "terms": terms.count])
    // Warm the CTC path once.
    let warm = try load(clips[clips.count / 2])
    let wr = try await tdt(finalMgr, warm)
    _ = await session.rescore(text: wr.text, tokenTimings: wr.tokenTimings ?? [], audioSamples: warm)
    for path in clips {
        let audio = try load(path)
        let (r, finalSec) = try await timed { try await tdt(finalMgr, audio) }
        let timings = r.tokenTimings ?? []
        let (has, checkSec) = await timed { session.hasCTCRescoringCandidates(text: r.text, tokenTimings: timings) }
        let (res, rescoreSec) = await timed { await session.rescore(text: r.text, tokenTimings: timings, audioSamples: audio) }
        emit(["mode": "boost", "clip": URL(fileURLWithPath: path).lastPathComponent, "audioSec": Double(audio.count) / 16000,
              "finalSec": finalSec, "hasCandidates": has, "checkSec": checkSec, "rescoreSec": rescoreSec,
              "modified": res?.wasModified ?? false])
    }
    let row: [String: Any] = ["mode": "boost", "kind": "end", "peakMB": peakMB()]
    emit(row); print(row); exit(0)
}

// MARK: - Live modes

let useA = mode == "a" || mode.hasPrefix("ab")
let eouSize: StreamingChunkSize? = mode.hasSuffix("160") ? .ms160 : mode.hasSuffix("320") ? .ms320 : nil
let previewMgr = mode == "a" ? finalMgr : AsrManager(config: .default, models: models)
if previewMgr !== finalMgr { _ = try await tdt(previewMgr, [Float](repeating: 0.001, count: 16000)) }
var eou: StreamingEouAsrManager?
if let eouSize {
    let m = StreamingEouAsrManager(chunkSize: eouSize)
    let (_, t) = try await timed { try await m.loadModels() }
    _ = try await m.process(audioBuffer: pcm([Float](repeating: 0.001, count: 16000)))
    _ = try await m.finish(); await m.reset()
    eou = m
    emit(["mode": mode, "kind": "setup", "eouLoadSec": t, "footprintAfterEouMB": footprintMB()])
}

for (ci, path) in clips.enumerated() {
    let audio = try load(path)
    let shared = Shared()
    let step = 1600
    var cont: AsyncStream<(Double, [Float])>.Continuation!
    let stream = AsyncStream<(Double, [Float])> { cont = $0 }
    let t0 = now() + 0.05

    let feeder = Task {
        var i = 0
        while i * step < audio.count {
            let slice = audio[(i * step)..<min(audio.count, (i + 1) * step)]
            await sleepUntil(t0 + Double(i + 1) * 0.1)
            shared.append(slice)
            cont.yield((now(), Array(slice)))
            i += 1
        }
        cont.finish()
    }

    let previewTask: Task<([Pass], [Double]), Never>? = useA ? Task {
        var passes: [Pass] = [], late: [Double] = []
        var tick = t0 + 0.5
        while true {
            await sleepUntil(tick)
            if shared.released { break }
            let snap = shared.snapshot()
            if snap.count < 4800 { tick += 0.1; continue }
            let s = now()
            shared.inFlight = true
            let r = try? await tdt(previewMgr, snap)
            shared.inFlight = false
            let e = now()
            passes.append(Pass(sched: tick, start: s, end: e, audioSec: Double(snap.count) / 16000, text: r?.text ?? ""))
            let next = tick + 1.0
            if e > next { late.append(e - next) }
            tick = max(next, e)
        }
        return (passes, late)
    } : nil

    let eouTask: Task<([Double], [Double]), Never>? = eou.map { m in
        Task {
            await m.setPartialCallback { text in shared.addPartial(now(), text) }
            var proc: [Double] = [], lag: [Double] = []
            for await (arrived, chunk) in stream {
                let s = now()
                _ = try? await m.process(audioBuffer: pcm(chunk))
                let e = now()
                proc.append(e - s); lag.append(e - arrived)
            }
            return (proc, lag)
        }
    }
    if eou == nil { Task { for await _ in stream {} } }

    await feeder.value
    let release = now()
    shared.released = true
    let inFlightAtRelease = shared.inFlight
    // Final pass starts the moment the key is released.
    var finalErr = ""
    var final: ASRResult?
    do { final = try await tdt(finalMgr, audio) } catch { finalErr = String(describing: type(of: error)) }
    let finalEnd = now()

    let (passes, late) = await previewTask?.value ?? ([], [])
    let (proc, lag) = await eouTask?.value ?? ([], [])
    var eouFinishSec = 0.0
    if let m = eou {
        let s = now(); _ = try? await m.finish(); eouFinishSec = now() - s
        await m.reset()
    }

    let finalWords = words(final?.text ?? "")
    let tokenStart = final?.tokenTimings?.first?.startTime ?? -1
    let speechStart = onsetSec(audio)
    // Live text history: A passes, or EOU partials, whichever drives the display.
    let live: [(Double, String)] = eou != nil
        ? shared.allPartials()
        : passes.map { ($0.end, $0.text) }
    let beforeRelease = live.filter { $0.0 <= release }
    let firstLive = live.first { !words($0.1).isEmpty }
    let firstShown = firstLive.map { $0.0 - t0 - speechStart }
    let firstWords = words(firstLive?.1 ?? "")
    // First update whose opening word is the final text's opening word.
    let firstGood = live.first { words($0.1).first.map { $0 == finalWords.first } ?? false }
    let shownBeforeSpeech = live.filter { $0.0 - t0 < speechStart && !words($0.1).isEmpty }.count
    let lastLive = words(beforeRelease.last?.1 ?? "")
    let fl = flicker(beforeRelease.map { $0.1 })
    let shownTimes = beforeRelease.map { $0.0 }
    let intervals = zip(shownTimes.dropFirst(), shownTimes).map { $0 - $1 }
    // A passes that ran beside B, when both are live.
    let aFl = flicker(passes.filter { $0.end <= release }.map { $0.text })
    let aLast = words(passes.last { $0.end <= release }?.text ?? "")

    var row: [String: Any] = [
        "mode": mode, "clip": URL(fileURLWithPath: path).lastPathComponent, "audioSec": Double(audio.count) / 16000,
        "speechStartSec": speechStart, "firstTokenSec": tokenStart, "firstLiveSec": firstShown ?? -999,
        "firstLiveAtSec": firstLive.map { $0.0 - t0 } ?? -999, "firstLiveWordCount": firstWords.count,
        "firstGoodLiveSec": firstGood.map { $0.0 - t0 - speechStart } ?? -999,
        "updatesWithWordsBeforeSpeech": shownBeforeSpeech,
        "firstLiveMatchesFinal": !firstWords.isEmpty && firstWords.first == finalWords.first,
        "liveEdits": edits(finalWords, lastLive), "refWords": finalWords.count,
        "liveUpdates": fl.updates, "flickerEvents": fl.events, "rewrittenWords": fl.words,
        "updateIntervals": intervals,
        "releaseToFinalSec": finalEnd - release, "finalComputeSec": final?.processingTime ?? -1,
        "previewInFlightAtRelease": inFlightAtRelease, "finalError": finalErr,
        "passCompute": passes.map { $0.end - $0.start }, "passAudioSec": passes.map { $0.audioSec },
        "passLate": late, "eouProc": proc, "eouLagMax": lag.max() ?? 0, "eouFinishSec": eouFinishSec,
        "footprintMB": footprintMB(),
    ]
    if eou != nil && useA {
        row["aLiveEdits"] = edits(finalWords, aLast)
        row["aFlickerEvents"] = aFl.events; row["aLiveUpdates"] = aFl.updates
        row["aFirstLiveSec"] = passes.first { !words($0.text).isEmpty }.map { $0.end - t0 - speechStart } ?? -1
    }
    emit(row)
    print("\(ci + 1)/\(clips.count) \(String(format: "%.1f", Double(audio.count) / 16000))s final \(String(format: "%.3f", finalEnd - release))s")
    try? await Task.sleep(nanoseconds: 300_000_000)
}
let end: [String: Any] = ["mode": mode, "kind": "end", "peakMB": peakMB()]
emit(end); print(end)
