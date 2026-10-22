# 02 — Can the FluidInference Core ML builds of Parakeet TDT v2 and v3 be retrained?

Researched 2026-10-23. Sources pinned to these revisions:
FluidInference v2 build `ee09c569`, v3 build `7dd20fe6` (Hugging Face);
NVIDIA v2 `ae9ad070`, v3 `541d1f99` (Hugging Face);
möbius `26f5fa80`, FluidAudio `c79c4106` (GitHub).
Numbers in square brackets point to the source list at the end.

## Answer

1. **The Core ML files cannot be fine-tuned directly.** Fine-tune NVIDIA's original `.nemo` checkpoint, then convert it again.
2. **The conversion can be reproduced closely.** FluidInference publishes the conversion and compression scripts, pins its tool versions, and has already shipped three retrained v3 models through this same path. The last step, which picks compressed variants and renames them to the published file names, is not one script. You redo it by hand from the file metadata.
3. **A retrained build loads into the FluidAudio Swift SDK without code changes** through `AsrModels.loadLocal(from:)`, provided the tokenizer stays the same (same vocabulary, same blank token number) and the file names and input/output shapes match.
4. **Licences allow commercial use and redistribution of a retrained model.** NVIDIA's weights are CC BY 4.0, which requires attribution and a note that you changed them. FluidInference's code is Apache 2.0. If you convert NVIDIA's weights yourself, FluidInference's model licence does not apply to your files.

## 1. Why the published builds cannot be fine-tuned as they are

- Both repos ship compiled Core ML bundles (`.mlmodelc`). v3 also ships `.mlpackage` sources (the editable, uncompiled Core ML format) [1][2].
- They are "ML Program" models, the newer Core ML format: "models are saved as MLProgram" [5]. Apple lists on-device updating (Core ML's built-in training) as "not yet supported" for ML Programs [21]. Only the older neural-network format, pipelines and nearest-neighbour models can be updated [22].
- The encoder weights are stored compressed, and the compression throws information away, so the training-precision weights cannot be recovered:
  - v2 and v3 `Encoder.mlmodelc`: "Palettized (6 bits)". Each weight is replaced by one of 64 shared values (a lookup table) [3][4].
  - v3 `Encoder_v2.mlmodelc`: int8, one scale per output channel. v3 `EncoderInt4.mlmodelc`: int4 [2][4].
  - Preprocessor: int8. Decoder and joint: float16 [3][4].
- The training code is not in the files either: the loss function, data loading and the TDT decoding used in training all live in NVIDIA NeMo. NVIDIA's cards say the model "can be used as a pre-trained checkpoint for inference or for fine-tuning on another dataset" in NeMo [17][18].

So the path is: fine-tune `nvidia/parakeet-tdt-0.6b-v2.nemo` or `-v3.nemo` in NeMo, then convert again with möbius. Both `.nemo` files are on Hugging Face [17][18].

## 2. Reproducing FluidInference's conversion

### Entry point

- `convert-parakeet.py convert --nemo-path <file>.nemo` loads any checkpoint with `EncDecRNNTBPEModel.restore_from`. It downloads the NVIDIA model only when no path is given [6, lines 30, 138–200]. A fine-tuned `.nemo` goes straight in.
- The v2 and v3 scripts are almost identical. The only code difference: v3's joint step also outputs the top 64 candidate tokens (`top_k_ids`, `top_k_logits`) [6][7]. `quantize_coreml.py` is byte-identical between v2 and v3 [8].

### Pinned environment

- Python 3.10.12, `coremltools==9.0b1`, `torch==2.7.0`, `nemo-toolkit==2.3.1`, `numpy==1.26.4`, locked with `uv` (`pyproject.toml` + `uv.lock`) [9].
- The published v2 and v3 `Encoder`, `Decoder`, `JointDecision` and `Preprocessor` files record coremltools 9.0b1 and torch 2.7.0 in their metadata, so they match these pins [3][4].

### How the model is split, and the fixed shapes

All parts use a fixed 15-second window (240,000 samples at 16 kHz). The minimum target is iOS 17 / macOS 14 [5][6, line 75]. Shapes as recorded in the published files [3][4]:

| Part | Inputs | Outputs |
|---|---|---|
| `Preprocessor` (audio → mel spectrogram) | `audio_signal` [1, 240000] (v2: variable length up to 15 s), `audio_length` | `mel` [1, 128, 1501], `mel_length` |
| `Encoder` | `mel` [1, 128, 1501], `mel_length` | `encoder` [1, 1024, 188], `encoder_length` |
| `Decoder` (2-layer LSTM prediction network) | `targets` [1, 1], `target_length`, `h_in`/`c_in` [2, 1, 640] | `decoder` [1, 640, 1], `h_out`, `c_out` |
| `JointDecision` (v2) / `JointDecisionv3` (v3), one step | `encoder_step` [1, 1024, 1], `decoder_step` [1, 640, 1] | `token_id`, `token_prob`, `duration`; v3 adds `top_k_ids`, `top_k_logits` [1, 1, 1, 64] |

The v2 preprocessor accepts variable-length input via `ct.RangeDim` [6, lines 277–280]. The v3 metadata records a fixed [1, 240000] [4].

### Compression settings used for each published file

| Published file | Setting (from file metadata) | Recipe |
|---|---|---|
| `Encoder.mlmodelc` (v2, v3) | "enc6bit-palettize": k-means, 6 bits | `quantize_coreml.py` variant `enc6bit-palettize`, `OpPalettizerConfig(mode="kmeans", nbits=6)` [8, lines 736–745] |
| `Preprocessor.mlmodelc` | "int8-linear": linear, per channel | variant `int8-linear`, `OpLinearQuantizerConfig(mode="linear", granularity="per_channel")` [8, lines 715–720] |
| `Decoder`, `JointDecision(v3)` | float16, no compression | export step [6] |
| `EncoderInt4.mlmodelc` (v3) | int4, per channel, iOS 18 / macOS 15 | `extra_encoder_variants.py` `enc-int4-linear-per-channel` [10, lines 130–140] |
| `Encoder_v2.mlmodelc` (v3) | int8, per channel, from float16 | v3 `config.json` [2]. No script in the v3 folder. The Ultra script describes itself as "the same encoding as the v3 `Encoder_v2.mlmodelc`" [12] |

`compile_modelc.py` compiles `.mlpackage` to `.mlmodelc` with `xcrun coremlcompiler` [11].

### Gaps in reproducing it exactly

- **No single script builds the published folder.** The converter writes names like `parakeet_encoder.mlpackage` [4, `mlpackages/metadata.json`]. Picking which compressed variant becomes `Encoder.mlmodelc`, renaming, and copying the vocabulary are done by hand.
- **Decoder precision is unclear.** The export metadata records `compute_precision: FLOAT32` [4], but the published decoder is stored as float16 [3][4]. I did not find which flag or step produced the float16 decoder.
- **Byte-identical output is impossible anyway.** New weights produce new 6-bit lookup tables. What has to match is the file names, input/output names and shapes, and tokenizer, and FluidAudio checks exactly those (section 3).
- **Avoid the 6-bit encoder for a retrained build.** FluidAudio says the original 6-bit `Encoder.mlmodelc` "flips tokens on some windows" (issue #760). Its fix and the Ultra build both use int8 per channel [13][14]. On the Ultra weights, int8 scored the same word error rate as float16 [12].

### FluidInference has already done this three times (v3 only)

- **Parakeet Ultra:** moondream's "full-precision post-training" of v3. Every part was exported again in the v3 file layout. 651 of 723 non-preprocessor tensors differ from NVIDIA v3. The preprocessor and vocabulary files are "the v3 copies" [12][14].
- **Parakeet Redux:** a "ternary re-training" of v3. The decoder and joint were exported again with "same I/O as v3" by `export_decoder_joint.py`, which writes `Decoder.mlpackage` and `JointDecisionv3.mlpackage` [15].
- **Phonon-2:** Fermion Research's "quantization-aware re-training of v3, English only". Same tokenizer, 15 s window and `JointDecisionv3` layout [16].
- These scripts start from Hugging Face–format checkpoints and map tensor names back to NeMo names (`hf_to_nemo_name`) [15]. A NeMo fine-tune can use `convert-parakeet.py` directly instead.
- There is no retrained v2 build in FluidAudio [13].

## 3. Dropping a retrained build into the FluidAudio Swift SDK

- `AsrModels.loadLocal(from:version:configuration:encoderPrecision:encoderComputeUnits:)` loads "the exact compiled directory you supply" and never downloads anything. Its doc comment says it is for "compatible community weights" [13, `AsrModels.swift` lines 330–380][19].
- Files it requires [13, `ModelNames.swift` lines 509–552, `AsrModels.swift` lines 285–310]:
  - v2: `Preprocessor.mlmodelc`, `Encoder.mlmodelc`, `Decoder.mlmodelc`, `JointDecision.mlmodelc`, `parakeet_vocab.json`.
  - v3: the same, except `JointDecisionv3.mlmodelc`. The encoder can be `Encoder.mlmodelc`, `Encoder_v2.mlmodelc` or `EncoderInt4.mlmodelc`, selected by `ParakeetEncoderPrecision` (`.int8` default / `.int8V2` / `.int4`) [13, `ModelNames.swift` lines 432–453].
- The vocabulary must contain "every token before the blank ID" [13, `AsrModels.swift` line 358]. The blank ID is hard-coded per version: 1024 for v2, 8192 for v3 [13, `AsrModels.swift` lines 54–58]. **Fine-tune without changing the tokenizer.** A new vocabulary size breaks this check and the joint output size.
- FluidAudio's Orukeet guide is a worked example of this path: a third-party v3 adaptation loaded with `loadLocal(from:version: .v3)`. Its `.mlpackage` files are compiled on the user's Mac with `MLModel.compileModel(at:)` [19].
- To be served through `downloadAndLoad` from a Hugging Face repo instead of a local folder, a build needs a new `AsrModelVersion` case and repo entry in FluidAudio. Ultra, Redux and Phonon-2 each got one [13, `AsrModels.swift` lines 4–22]. That is an SDK change; `loadLocal` is not.

## 4. Licences

| Item | Licence | Source |
|---|---|---|
| `nvidia/parakeet-tdt-0.6b-v2` / `-v3` weights | CC BY 4.0; "ready for commercial/non-commercial use" | [17][18] |
| FluidInference v2 Core ML build | CC BY 4.0 in the card metadata; the card says "See the LICENSE file", but the repo has no LICENSE file | [1] |
| FluidInference v3 Core ML build | Metadata says CC BY 4.0; the card's License section says "Apache 2.0". **The card contradicts itself.** | [2] |
| möbius conversion scripts | Apache 2.0 | [5] (repo `LICENSE`) |
| FluidAudio SDK | Apache 2.0 | [13] (repo `LICENSE`) |

What CC BY 4.0 allows and requires for a retrained model [20]:

- Allows: copying and sharing, and producing and sharing "Adapted Material" (a fine-tuned model counts) (§2(a)(1)). No commercial-use restriction.
- Requires when shared: credit to the creator, a copyright notice, a link to the licence, a note about the disclaimer of warranties, a link to the original "to the extent reasonably practicable", a note that you modified it, and a statement that it is under CC BY 4.0 (§3(a)(1)).
- Your own licence on your changes "must not prevent recipients of the Adapted Material" from complying with CC BY (§3(a)(4)). You may not add terms or "Effective Technological Measures" (for example encryption or DRM) that restrict what recipients may do with the licensed material (§2(a)(5)(B)).
- Patent and trademark rights are not licensed (§2(b)(2)).

For Fluidity:

- **If you convert NVIDIA's weights yourself,** the FluidInference model licence does not cover your output. Only NVIDIA's CC BY 4.0 does, plus Apache 2.0 notices if you redistribute möbius code.
- **If you copy FluidInference's `Preprocessor.mlmodelc` or vocabulary,** as Ultra and Redux did [12][15], credit FluidInference too. Which licence applies to those files is unclear (see the contradiction above). Exporting the preprocessor yourself avoids the question.
- **Encrypting the model inside the app** may conflict with §2(a)(5)(B). This needs a lawyer's reading.
- **Licences for the crowdsourced user recordings** are a separate question, not covered here.

## 5. v2 (English) vs v3 (25 languages) for an English-only app

| | v2 | v3 |
|---|---|---|
| Languages | English | 25 European languages [18] |
| Tokenizer | 1,024 tokens (blank = 1024); `parakeet_vocab.json` has 1,031 entries [1][13] | 8,192 tokens (blank = 8192) [13][18] |
| Joint / decoder size | 3.4 MB / 14 MB [1] | 12.6 MB / 23.6 MB [2] |
| LibriSpeech test-clean, FluidAudio benchmark | 2.1 % average WER (word error rate) [23] | 2.5 % on the same benchmark page [23]; 2.27 % corpus-level in the newer v3-family table [23] |
| FluidAudio's advice | "Use v2 if you only need English, it is a bit more accurate" [23] | Library default [13] |
| Encoder files | `Encoder.mlmodelc` (6-bit) only, in the current layout. The repo also holds older parts (`ParakeetEncoder*`, `Melspectogram`, `RNNTJoint`) from coremltools 8.3 that the current loader does not use [1][3][13] | 6-bit, int8 (fixes #760) and int4 encoders [2][13] |
| Top-64 candidate tokens from the joint | No | Yes, used by FluidAudio for "language-aware script filtering" and by the converter for "host-side re-ranking with contextual biasing" [7][13] |
| Retrained builds already working in FluidAudio | None | Ultra, Redux, Phonon-2 (Phonon-2 is English only) [12][15][16] |

For an English-only app:

- **v2 is smaller and scored better on English** in FluidAudio's own benchmark.
- **v3 has all the existing retraining precedent,** the int8 encoder fix (#760), and the top-64 output.
- **Phonon-2 shows a v3 retrain can drop to English only** while keeping the v3 file layout.
- **Fine-tuning v3 on English data alone** will likely cost accuracy in the other 24 languages. That does not matter for this app, and I found no source that measured it.

## Not established

- I did not run the converter or confirm that a `.nemo` saved by a NeMo version other than 2.3.1 loads in the pinned environment.
- Which step produced the float16 `Decoder` given the recorded `FLOAT32` export setting.
- Where the exact script for the v3 `Encoder_v2.mlmodelc` lives. The Ultra int8 script says it uses the same encoding.
- Whether coremltools' k-means palettization gives the same result on every run (only matters if you keep the 6-bit encoder).
- Which licence FluidInference intends for its v3 build (CC BY 4.0 or Apache 2.0).
- Legal reading of CC BY §2(a)(5)(B) for an encrypted, app-bundled model. This is not legal advice.

## Sources

1. FluidInference v2 build, files and card: https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v2-coreml/tree/ee09c569f73759e6d44c9bd16766f477b2b36d39 , https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v2-coreml/blob/main/README.md
2. FluidInference v3 build, files, card and `config.json`: https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml/tree/7dd20fe6b1797d35f5e3307e8b1732d9a178edfe , https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml/blob/main/README.md , https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml/blob/main/config.json
3. v2 per-file metadata, e.g. https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v2-coreml/blob/main/Encoder.mlmodelc/metadata.json (also `Decoder`, `JointDecision`, `Preprocessor`, `ParakeetEncoder_v2`, `ParakeetEncoder_4bit_par`)
4. v3 per-file metadata, e.g. https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml/blob/main/Encoder.mlmodelc/metadata.json (also `EncoderInt4`, `Decoder`, `JointDecision*`, `Preprocessor`, `MelEncoder`), and https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml/blob/main/mlpackages/metadata.json
5. möbius v3 conversion README: https://github.com/FluidInference/mobius/blob/26f5fa8059d5ab3d34449adce6ff6ed86734e522/models/stt/parakeet-tdt-v3-0.6b/coreml/README.md (repo licence: https://github.com/FluidInference/mobius/blob/26f5fa8059d5ab3d34449adce6ff6ed86734e522/LICENSE)
6. `convert-parakeet.py` (v3; v2 differs only in model id and top-K): https://github.com/FluidInference/mobius/blob/26f5fa8059d5ab3d34449adce6ff6ed86734e522/models/stt/parakeet-tdt-v3-0.6b/coreml/convert-parakeet.py , https://github.com/FluidInference/mobius/blob/26f5fa8059d5ab3d34449adce6ff6ed86734e522/models/stt/parakeet-tdt-v2-0.6b/coreml/convert-parakeet.py
7. `individual_components.py` (v3 top-K): https://github.com/FluidInference/mobius/blob/26f5fa8059d5ab3d34449adce6ff6ed86734e522/models/stt/parakeet-tdt-v3-0.6b/coreml/individual_components.py
8. `quantize_coreml.py`: https://github.com/FluidInference/mobius/blob/26f5fa8059d5ab3d34449adce6ff6ed86734e522/models/stt/parakeet-tdt-v3-0.6b/coreml/quantize_coreml.py
9. `pyproject.toml` / `uv.lock`: https://github.com/FluidInference/mobius/blob/26f5fa8059d5ab3d34449adce6ff6ed86734e522/models/stt/parakeet-tdt-v3-0.6b/coreml/pyproject.toml
10. `extra_encoder_variants.py`: https://github.com/FluidInference/mobius/blob/26f5fa8059d5ab3d34449adce6ff6ed86734e522/models/stt/parakeet-tdt-v3-0.6b/coreml/extra_encoder_variants.py
11. `compile_modelc.py`: https://github.com/FluidInference/mobius/blob/26f5fa8059d5ab3d34449adce6ff6ed86734e522/models/stt/parakeet-tdt-v3-0.6b/coreml/compile_modelc.py
12. Parakeet Ultra conversion: https://github.com/FluidInference/mobius/blob/26f5fa8059d5ab3d34449adce6ff6ed86734e522/models/stt/parakeet-ultra/coreml/README.md , https://github.com/FluidInference/mobius/blob/26f5fa8059d5ab3d34449adce6ff6ed86734e522/models/stt/parakeet-ultra/coreml/quantize_encoder_int8.py
13. FluidAudio source: https://github.com/FluidInference/FluidAudio/blob/c79c4106b954f81205113c3343e5a7e59a1089b5/Sources/FluidAudio/ModelNames.swift , https://github.com/FluidInference/FluidAudio/blob/c79c4106b954f81205113c3343e5a7e59a1089b5/Sources/FluidAudio/ASR/Parakeet/SlidingWindow/TDT/AsrModels.swift , model guide https://github.com/FluidInference/FluidAudio/blob/c79c4106b954f81205113c3343e5a7e59a1089b5/Documentation/Models.md (repo licence: https://github.com/FluidInference/FluidAudio/blob/c79c4106b954f81205113c3343e5a7e59a1089b5/LICENSE)
14. FluidAudio Ultra page: https://github.com/FluidInference/FluidAudio/blob/c79c4106b954f81205113c3343e5a7e59a1089b5/Documentation/ASR/ParakeetUltra.md
15. Parakeet Redux conversion: https://github.com/FluidInference/mobius/blob/26f5fa8059d5ab3d34449adce6ff6ed86734e522/models/stt/parakeet-redux/coreml/README.md , https://github.com/FluidInference/mobius/blob/26f5fa8059d5ab3d34449adce6ff6ed86734e522/models/stt/parakeet-redux/coreml/export_decoder_joint.py , https://github.com/FluidInference/mobius/blob/26f5fa8059d5ab3d34449adce6ff6ed86734e522/models/stt/parakeet-redux/coreml/redux_weights.py
16. FluidAudio Phonon-2 page: https://github.com/FluidInference/FluidAudio/blob/c79c4106b954f81205113c3343e5a7e59a1089b5/Documentation/ASR/Phonon2.md
17. NVIDIA v2 card: https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2/blob/ae9ad07059c7c739ffaf932226a8fe64ae2620b0/README.md
18. NVIDIA v3 card: https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3/blob/541d1f99c6b0c3cd0b11a95167540bb8edefd82b/README.md
19. FluidAudio Orukeet guide (local loading): https://github.com/FluidInference/FluidAudio/blob/c79c4106b954f81205113c3343e5a7e59a1089b5/Documentation/Orukeet.md
20. CC BY 4.0 legal code: https://creativecommons.org/licenses/by/4.0/legalcode.en
21. Apple coremltools, ML Programs vs neural networks: https://apple.github.io/coremltools/docs-guides/source/comparing-ml-programs-and-neural-networks.html
22. Apple coremltools, updatable models: https://apple.github.io/coremltools/docs-guides/source/updatable-model-examples.html
23. FluidAudio benchmarks: https://github.com/FluidInference/FluidAudio/blob/c79c4106b954f81205113c3343e5a7e59a1089b5/Documentation/Benchmarks.md
