import Foundation

/// The on-device speech models Rillo can dictate with. The raw value is saved in each dictation record.
public enum SpeechModelID: String, Codable, CaseIterable, Sendable {
    case parakeetTDTv2 = "parakeet-tdt-0.6b-v2"
    case appleBuiltIn = "apple-speech"
    case fluidSpeechPro = "fluid-speech-pro"
}

/// One row of the model catalogue: what the settings pane shows about a model.
public struct SpeechModel: Sendable, Identifiable {
    public enum Install: Sendable {
        case partOfMacOS
        case download(bytes: Int64, approximate: Bool, folder: String)
    }

    /// Measured figures; nil when the model has not been measured.
    public struct Figures: Sendable {
        public var firstWordMs: Int
        public var updateEveryMs: Int
        public var liveVsFinalPercent: Double
    }

    public var id: SpeechModelID
    public var name: String
    public var language: String
    public var install: Install
    public var figures: Figures?
    /// The attribution the model's licence asks for, shown with it.
    public var credit: String?

    public static let all: [SpeechModel] = [
        SpeechModel(
            id: .parakeetTDTv2, name: "Parakeet TDT v2", language: "English",
            install: .download(bytes: 443_000_000, approximate: false, folder: "parakeet-tdt-0.6b-v2-coreml"),
            figures: Figures(firstWordMs: 546, updateEveryMs: 383, liveVsFinalPercent: 1.6)),
        SpeechModel(
            id: .appleBuiltIn, name: "Apple Speech", language: "10+ languages",
            install: .partOfMacOS, figures: nil),
        // CC BY 4.0: the credit line is the one its NOTICE file asks for.
        SpeechModel(
            id: .fluidSpeechPro, name: "Fluid Speech Pro", language: "25 languages",
            install: .download(bytes: fluidSpeechProFiles.totalBytes, approximate: false, folder: "fluid-speech-pro-coreml"),
            figures: nil,
            credit: "Fluid Speech Pro by FluidVoice. Built on NVIDIA Parakeet TDT 0.6B v3 and Moondream Parakeet Ultra."),
    ]

    /// Fluid Speech Pro's Core ML files, which FluidAudio does not download for it.
    static let fluidSpeechProFiles = PinnedFiles(
        repo: "FluidVoice-Labs/fluid-speech-pro-coreml", revision: "3b9d38a93d606f84011e5a0a669b7ea146375a22",
        files: [
                ("Decoder.mlmodelc/analytics/coremldata.bin", 243, "d172cb80cbf3a2cd768952557164db1b50b9c6aef16af3653d2fd7c03d9fe8e5"),
                ("Decoder.mlmodelc/coremldata.bin", 491, "5059c27aa8cc44eb735247d335e18da599d15e30d67b3d2d5633679fc5806f8a"),
                ("Decoder.mlmodelc/metadata.json", 3_311, "47ee2ad3514945b6ee3ccd4171ed3b2318e38f3b929e4398ce33b50aca606083"),
                ("Decoder.mlmodelc/model.mil", 11_823, "9d605291dfdaef07ef88b8d3dbf0702766f1ceea5649d5d6dee4d2322d8fa678"),
                ("Decoder.mlmodelc/weights/weight.bin", 23_604_992, "7b3e3a4e3fbb580ae990613915f8ea2309226d85999ae37120912b8352d1df9e"),
                ("Encoder.mlmodelc/analytics/coremldata.bin", 243, "ac53d09c1b1f7f00fd1a07a630d57c4193089b19fe0d3b1571a3ecf91be62aa4"),
                ("Encoder.mlmodelc/coremldata.bin", 427, "abfbc09cc0b8aba7911e38390390f1c5850e3665862238035052e015659ebb74"),
                ("Encoder.mlmodelc/metadata.json", 2_758, "cc74be4442be9fe7d6428aa238364d40e91d3c0ca4ce3cfa2f4fef4ad7a42cee"),
                ("Encoder.mlmodelc/model.mil", 621_903, "f71d68afe10e227c39d43af07c1aa1a88dd0eb2f63109a3e03711066e38a2e9d"),
                ("Encoder.mlmodelc/weights/weight.bin", 613_088_448, "4abdc3b4af2ff9b2843105f29677f0e674d2b08638b1ce6feac60876c235c659"),
                ("JointDecision.mlmodelc/analytics/coremldata.bin", 243, "3dd0d66c51f69d683c587d5c88f3256d5e1690105ecf9d8ca4b0c2b8e1c883c7"),
                ("JointDecision.mlmodelc/coremldata.bin", 462, "febdb37a5ad1a119539c33cf68fac1c51f80f40f82c90b6ef312033191ff4063"),
                ("JointDecision.mlmodelc/metadata.json", 2_728, "36fa268dd3c132c7305bbe1f17b5891a00f91caf0a883782375c35a97e2f4ada"),
                ("JointDecision.mlmodelc/model.mil", 7_178, "618bc532db01d5d80da27d0137e4b50cf2f56dde54e0686a4a1e732d74c1a55c"),
                ("JointDecision.mlmodelc/weights/weight.bin", 12_642_764, "f0939e8807dded497926a7c3634af698557ec8b155d804f8f40e367e97f90849"),
                ("LICENSE", 18_657, "9ba9550ad48438d0836ddab3da480b3b69ffa0aac7b7878b5a0039e7ab429411"),
                ("NOTICE", 451, "fb46bca8b337792a755ec6c77e0e33ebd27d181f46540e4b88382d179942625c"),
                ("Preprocessor.mlmodelc/analytics/coremldata.bin", 243, "886396da81b6b29d60d79d903bd5d1f00077a7a4323f40cd2e9214d4205d8e6b"),
                ("Preprocessor.mlmodelc/coremldata.bin", 429, "38f130eac9ffde8c684043d76e3eecdd3b6f9564d9efa59f7a87a34a272a4901"),
                ("Preprocessor.mlmodelc/metadata.json", 2_606, "c25d98c19a181b7fa65ee50c34f5066f67172c22f0bf116a42b59443ee4bc37d"),
                ("Preprocessor.mlmodelc/model.mil", 11_891, "71d4ad016334b3ad73ea7b69b6813feefe3b81f59e0b5e924f90f088cb02a7c9"),
                ("Preprocessor.mlmodelc/weights/weight.bin", 2_150_580, "44180071e400951080786feb46452bffc4fb26363a703655ebadb760c8ad4030"),
                ("config.json", 646, "b688c4d174c4fb043b368dad402ae91d4ae68cf2a53db42ff663340913c907db"),
                ("parakeet_v3_vocab.json", 151_122, "7ec60e05f1b24480736ec0eed40900f4626bce1fa9a60fd700ec7e2a59198735"),
                ("parakeet_vocab.json", 151_122, "7ec60e05f1b24480736ec0eed40900f4626bce1fa9a60fd700ec7e2a59198735"),
        ])

    public static func model(_ id: SpeechModelID) -> SpeechModel {
        all.first { $0.id == id }!
    }
}

extension SpeechModelID: DownloadableModelID {
    public var downloadBytes: Int64? {
        guard case .download(let bytes, _, _) = SpeechModel.model(self).install else { return nil }
        return bytes
    }
}
