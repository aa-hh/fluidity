// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RilloCore",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "RilloCore", targets: ["RilloCore"]),
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
            name: "RilloCore",
            dependencies: [.product(name: "FluidAudio", package: "FluidAudio")],
            // Folder notes for agents, not sources.
            exclude: [
                "AudioCapture/AGENTS.md",
                "DictationController/AGENTS.md",
                "DictationStore/AGENTS.md",
                "EditWatcher/AGENTS.md",
                "FocusedField/AGENTS.md",
                "Hotkey/AGENTS.md",
                "ModelCoordinator/AGENTS.md",
                "Paster/AGENTS.md",
                "SpeechModels/AGENTS.md",
                "Transcriber/AGENTS.md",
            ],
        ),
        .target(name: "RilloTestSupport", path: "Tests/TestSupport"),
        .testTarget(name: "DictationTests", dependencies: ["RilloCore", "RilloTestSupport"]),
        .testTarget(name: "AudioTests", dependencies: ["RilloCore", "RilloTestSupport"]),
        .testTarget(name: "CleanupTests", dependencies: ["RilloCore", "RilloTestSupport"]),
        .testTarget(name: "FieldTests", dependencies: ["RilloCore", "RilloTestSupport"]),
    ]
)
