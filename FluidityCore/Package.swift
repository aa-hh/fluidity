// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FluidityCore",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "FluidityCore", targets: ["FluidityCore"]),
    ],
    dependencies: [
        // Pinned to the revision the live-words spike measured (ADR 0002).
        // No traits: speech-to-text and voice detection only, no TTS or diarizer.
        .package(
            url: "https://github.com/FluidInference/FluidAudio.git",
            revision: "1b0ed50d686873128a4129b3510ce3914c849bab",
            traits: []
        ),
    ],
    targets: [
        .target(
            name: "FluidityCore",
            dependencies: [.product(name: "FluidAudio", package: "FluidAudio")],
            // Folder notes for agents, not sources.
            exclude: [
                "AudioCapture/AGENTS.md",
                "DictationController/AGENTS.md",
                "DictationStore/AGENTS.md",
                "EditWatcher/AGENTS.md",
                "FocusedField/AGENTS.md",
                "Hotkey/AGENTS.md",
                "Paster/AGENTS.md",
                "SpeechModels/AGENTS.md",
                "Transcriber/AGENTS.md",
            ],
        ),
        .target(name: "FluidityTestSupport", path: "Tests/TestSupport"),
        .testTarget(name: "DictationTests", dependencies: ["FluidityCore", "FluidityTestSupport"]),
        .testTarget(name: "AudioTests", dependencies: ["FluidityCore", "FluidityTestSupport"]),
        .testTarget(name: "CleanupTests", dependencies: ["FluidityCore", "FluidityTestSupport"]),
        .testTarget(name: "FieldTests", dependencies: ["FluidityCore", "FluidityTestSupport"]),
    ]
)
