// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "RilloCore",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "RilloCore", targets: ["RilloCore"]),
    ],
    dependencies: [
        // Fluid Voice's copy of FluidAudio, pinned (AA-470): it loads Fluid Speech Pro with its own decoding,
        // which scored 3.6% against 3.9% through FluidInference/FluidAudio. It split from that one in March 2026,
        // so it has no Parakeet Unified and no word-list pre-check. It declares no traits, so TTS and the diarizer
        // can't be left out.
        .package(
            url: "https://github.com/altic-dev/FluidAudio.git",
            revision: "386f7195670b77f2954c7ee143ec63fcb50b6c3b"
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
