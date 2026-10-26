// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LiveWordsSpike",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", revision: "1b0ed50d686873128a4129b3510ce3914c849bab"),
    ],
    targets: [
        .executableTarget(
            name: "LiveWordsSpike",
            dependencies: [.product(name: "FluidAudio", package: "FluidAudio")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
