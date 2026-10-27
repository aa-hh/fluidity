import FluidAudio
import Foundation

/// `ModelFetching` over FluidAudio's model folders under Application Support. Untested: it needs real files and the network.
public struct FluidAudioModelFetcher: ModelFetching {
    private static let unifiedConfig = StreamingModelVariant.parakeetUnified320ms.unifiedConfig!

    public init() {}

    private var modelsDirectory: URL { MLModelConfigurationUtils.defaultModelsDirectory(for: nil) }

    public func isInstalled(_ id: SpeechModelID) -> Bool {
        switch id {
        case .appleBuiltIn:
            return true
        case .parakeetTDTv2:
            return AsrModels.modelsExist(at: AsrModels.defaultCacheDirectory(for: .v2), version: .v2)
        case .parakeetUnified:
            let folder = modelsDirectory.appendingPathComponent(Repo.parakeetUnified.folderName, isDirectory: true)
            let files = [
                ModelNames.ParakeetUnified.streamingEncoderFile(precision: .int8, contextSuffix: Self.unifiedConfig.contextSuffix),
                ModelNames.ParakeetUnified.decoderFile,
                ModelNames.ParakeetUnified.jointDecisionFile,
                ModelNames.ParakeetUnified.vocab,
            ]
            return files.allSatisfy { FileManager.default.fileExists(atPath: folder.appendingPathComponent($0).path) }
        }
    }

    public func availableBytes() -> Int64 {
        // The Models folder may not exist before the first download; its nearest existing parent is on the same volume.
        var url = modelsDirectory
        while !FileManager.default.fileExists(atPath: url.path), url.pathComponents.count > 1 {
            url.deleteLastPathComponent()
        }
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage ?? 0
    }

    public func download(_ id: SpeechModelID, progress: @escaping @Sendable (Double) -> Void) async throws {
        switch id {
        case .appleBuiltIn:
            return
        case .parakeetTDTv2:
            try await AsrModels.download(version: .v2) { progress($0.fractionCompleted) }
        case .parakeetUnified:
            // `loadModels` is the only download path that knows the manager's required files; the loaded models are dropped at once.
            let manager = StreamingUnifiedAsrManager(config: Self.unifiedConfig)
            try await manager.loadModels(to: nil) { progress($0.fractionCompleted) }
            await manager.cleanup()
        }
    }

    public func removeFiles(for id: SpeechModelID) throws {
        guard case .download(_, _, let folder) = SpeechModel.model(id).install else { return }
        let url = modelsDirectory.appendingPathComponent(folder, isDirectory: true)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }
}
