# AA-291: Does training on generated speech improve recognition of real dictation?

Researched 2026-10-23. Every claim carries its source link. "WER" means word error rate: the share of words the recogniser gets wrong. "Relative" means the drop as a share of the starting WER (10% to 9% is a 10% relative drop).

## Short answer

- Yes, with conditions. Mixing generated speech with real speech improved recognition of real speech in most controlled studies below; two did not (the Parakeet card, and raw generated audio in the banking study). Gains are 4-13% relative when plenty of real speech is present, up to 33% with little real speech, and 28-65% relative when the generated speech carries words or a domain the real data lacks (names, drug names, new topics).
- Generated speech alone is much worse than real speech. It works as a supplement, never a replacement.
- The one public Parakeet TDT 0.6B attempt (about 10% generated audio, atypical speech) gave no gain: 10.52% to 10.87% WER.
- Many voices matter more than voice quality. One high-quality voice made results much worse; three voices were not enough.
- Too much generated audio hurts. Most studies peaked with half or less of each training batch generated; one (WSJ text adaptation) did best at two-thirds, and one accent study used three-quarters.
- For Fluidity the best-supported bet is narrow: teach Parakeet the owner's words (names from the personal word list, number and time formats) using his own texts, many voices including a clone of his own voice, room-echo augmentation, and real audio in every batch.

## 1. Published results

### 1a. Conformer and Parakeet-family models (closest to Fluidity)

**NVIDIA, Conformer-transducer in NeMo, text turned into spectrograms during training** (Bataev et al., Interspeech 2023, https://arxiv.org/abs/2302.14036; read from the PDF, https://arxiv.org/pdf/2302.14036)
- Generated-only training on LibriSpeech texts, tested on real LibriSpeech test-other: 22.1% WER, against 6.6% for the same model trained on real audio (Table 2). Generated audio alone is 3x worse.
- With 45 hours of text-to-speech training data the generator gave 61.8% WER; with 468 hours, 45.5%; adding their spectrogram "enhancer" brought it to 22.1% (Table 2). The quality of the voice engine changes results a lot.
- Adapting a 24,000-hour pretrained Conformer-L to a new domain (smart-home commands, SLURP) with text only: 23.5% to 15.0% WER, 36.2% relative (Table 6).
- WSJ: real audio-text pairs plus generated audio from a large text corpus, mixed 1 real : 2 generated, gave 1.5% WER, against 7.2% for the starting model and 3.1% for real pairs alone (Tables 7-8). A 1:1 mix gave 1.7%.
- BatchNorm layers (layers that store average statistics of the training audio) mismatch when generated and real audio differ. The authors fused BatchNorm into a plain trainable layer before fine-tuning, which helped (Table 4: 33.9 to 32.5 test WER).
- NeMo ships this as `ASRWithTTSModel`: a frozen FastPitch text-to-spectrogram model attached to a CTC or RNN-T model, with an `asr_model_fuse_bn` option and sampling settings `asr_tts_sampling_technique` / `asr_tts_sampling_probabilities` for mixing text-only and audio data (https://docs.nvidia.com/nemo-framework/user-guide/latest/nemotoolkit/asr/models.html, https://docs.nvidia.com/nemo-framework/user-guide/latest/nemotoolkit/asr/configs.html). The configs page lists `ctc_bpe`, `rnnt_bpe` and `hybrid_rnnt_ctc_bpe`; TDT (the Parakeet decoder) is not listed. Only FastPitch voices are supported, so the accent range is whatever the FastPitch checkpoint has.
- FastConformer's default NeMo config uses BatchNorm in its convolution blocks (`conv_norm_type: 'batch_norm'`, https://raw.githubusercontent.com/NVIDIA/NeMo/main/examples/asr/conf/fastconformer/fast-conformer_transducer_bpe.yaml). I did not open the Parakeet checkpoint to confirm it keeps that default.

**Parakeet TDT 0.6B v3 fine-tuned with generated speech, atypical (dysarthric) English** (self-published model card, not peer reviewed, https://huggingface.co/dys-asr/parakeet-tdt-0.6b-syn)
- 103.1 hours of generated speech (Fun-CosyVoice3 cloning real patients' voices) added to about 920 hours of real audio, so about 10% of hours.
- Result: 10.87% WER against 10.52% without the generated audio. The card says the generated set "did not improve this benchmark".
- The card's own caveats: not a controlled comparison (different max audio length), one seed, cloned voices came from speakers already in the real data so they added no new speakers.
- A FastConformer with personalised generated dysarthric speech was mixed: one generated set cut WER from 21.9 to 19.0, another raised it to 23.3 (https://arxiv.org/pdf/2508.06391, Table IV, as summarised by search; I did not read the full paper).

**Hard-Synth** (Conformer and Transformer trained from scratch, LibriSpeech 100 h real, https://arxiv.org/html/2411.13159)
- Voice cloning (VoiceCraft) of the real speakers the weak model found hardest, reading new texts rewritten by a language model.
- Conformer test-other: 17.43% to 16.67% WER (4.4% relative); dev-other 6.5% relative (Table III).
- Amount sweep (Table IV): 8.62 h generated gave 17.16% test-other, 15.38 h gave 16.74%, 30.87 h gave 17.21%. Doubling the generated audio past about 15% of the real hours erased the gain.
- F5-TTS as the voice engine averaged 11.55% against 11.43% for VoiceCraft (Table V).
- Failure modes listed: long silences, missing words, repeated words. They dropped clips whose round-trip character error rate exceeded 10%.

### 1b. Older end-to-end studies on LibriSpeech

**NVIDIA 2018, Wave2Letter+ with Tacotron-2 voices** (Li et al., https://arxiv.org/abs/1811.00707; numbers from the PDF)
- Natural / generated sampling ratio on the 34-layer model, test-other WER (Table 2): real only 16.21%; 50/50 15.47%; 33/66 15.81%; generated only 81.78%.
- "A 50/50 split between the natural and synthetic seems to be a good ratio." They blamed the generated-only collapse on the voice engine having only 3 speakers.

**Google 2019, LAS model with multi-speaker Tacotron** (Rosenberg et al., https://arxiv.org/abs/1909.11699; numbers from the PDF)
- Full generated copy of LibriSpeech 960 h added to the real 960 h: test-other 13.89% to 13.78%, about 4% relative, only when speaker identities were sampled from real training speakers. Random speaker vectors made it worse (14.91%) (Table 1).
- A higher-quality single-speaker voice engine made results much worse: 13.55% / 24.84% (test-clean / test-other) against a 4.77% / 13.89% baseline. Their conclusion: "Multi-speaker TTS is necessary".
- Less real data, bigger gain: 100 h real alone 12.46% / 34.00%; plus 960 h generated 9.25% / 30.58% (Table 2).
- Topline: generating the test sentences' text (no test audio) took test-other from 13.89% to 11.8% (Table 3). Knowing the user's text is most of the value. Fluidity has exactly this: the owner's own dictation texts.
- Adding more varied generated text plateaued: 600k utterances gave 5% relative; 1.1M gave no further gain (Table 4).

**RWTH 2020, attention model** (Rossenbach et al., https://arxiv.org/abs/1912.09257)
- Up to 33% relative WER gain with 100 h real speech; up to 5% relative with 960 h real.

**RWTH 2024, generated-only training across model types** (Hilmes, Rossenbach, Schlüter, https://arxiv.org/html/2407.17997v2)
- Encoder-decoder model trained on 100 h of real audio: 18.9% dev-other. Same text, generated audio only: 37.6% (Tables 1-2). Older model types lost less.
- Bigger voice models narrowed the gap (30.5% at 2x width) but voice-model training loss did not predict recognition quality.

### 1c. Pretrained models (Whisper and others) with modern voice-cloning engines

**Speech back-translation, Whisper, XTTS and ChatTTS** (Wang et al., EMNLP 2025, https://aclanthology.org/2025.emnlp-main.629.pdf)
- Whisper-large-v3 plus 15,000 h real speech, then plus 500,000 h generated speech across 10 languages: 30% average error reduction over base Whisper-large-v3; high-resource languages (including English) 26% (Table 4; Section 5.5).
- A minimum intelligibility of the generated speech is required. Below their threshold, generated speech raised WER by up to 2 points; above it, gains levelled off around 3 points (Figure 6).
- Vietnamese, 3 h real in-domain: fine-tuning Whisper-medium on real only took WER from 25.4 to 21.6. Pretraining on 1,000 h generated then fine-tuning gave 20.4. Cloning voices from the in-domain real clips gave 20.1. Also fine-tuning the voice engine on the 3 h of real audio gave 18.6 (Table 3). Using your own real audio as the voice source beat generic voices.
- They prompted the voice engine with about 1 million de-duplicated real clips for speaker variety.

**LLM-based recogniser, banking domain, Qwen3-TTS voices** (https://arxiv.org/html/2606.29031v2)
- Real-only baseline 8.68% WER. Replacing part of the real data with generated data: best at 10-30% generated (8.45-8.85%); 90% generated gave 10.26% (Table IV).
- Adding generated data on top of all real data: raw generated audio did not beat the baseline (8.74% at 100% extra). Generated audio passed through room impulse responses (real room echo recordings) gave 8.01%, a 7.7% relative gain (Table V).
- Raw generated audio scored much higher on a perceived-quality model than real audio (UTMOS 4.36 against 2.08); adding room echo dropped it to 1.34 and made it more useful. Clean, studio-like generated audio is a mismatch, not an advantage.
- Pitch shift helped slightly; time stretch alone hurt slightly (Table VI).

**Few-shot generated accented speech** (wav2vec 2.0, https://arxiv.org/html/2604.27273)
- Generated audio helped only while real data was scarce. Real-only overtook real-plus-generated at about 8 real utterances (Indian English) and 25 (Korean English).
- Mixing generated with real data cut run-to-run spread sharply (standard deviation 3.11 to 0.49).

**Zero-shot voice cloning for accented English** (YourTTS + transformer CTC model, https://arxiv.org/pdf/2409.11107)
- With 10-90% of 20 h real Indian-English data, topping up with generated speech beat real-only at every size (for example 25% real: 11.80% to 10.15% WER, Table 2). They used 75% generated / 25% real for later runs.
- Generated-only fine-tuning got worse as the amount grew: 1.4 h generated changed WER by -6.4% / +5.0% (two voice engines), 12.6 h by -41.5% / -8.8% (Table 3). The authors call this overfitting to generated speech.
- Standard noise and echo augmentation on top of generated speech helped at small real-data sizes and hurt at larger ones (Table 5).

### 1d. Teaching new words with generated speech

- Amazon, RNN-T: generated audio for out-of-vocabulary words gave 57% relative WER reduction on utterances containing those words, with no loss on the full test set; they used elastic weight consolidation (a penalty that keeps important weights close to their old values) on the encoder (https://arxiv.org/abs/2011.11564).
- Amazon SynthASR, RNN-T: mostly generated speech for medication names, over 65% relative gain on the new task, no loss on existing tasks; used weighted multi-style training, encoder freezing and regularisation (https://arxiv.org/abs/2106.07803).
- Apple, language-model-written domain text plus controllable voices: 28% average relative WER drop on unseen domains, no loss on source domains (https://arxiv.org/abs/2309.10707).

### 1e. How many voices

No paper found gives a clean curve of gain against voice count. The evidence is indirect:
- 3 voices: generated-only training collapsed to 81.78% WER, which the authors blamed on too few speakers (https://arxiv.org/abs/1811.00707).
- 1 high-quality voice: much worse than multi-speaker generated speech (https://arxiv.org/abs/1909.11699).
- Speaker identities drawn from real training speakers beat random speaker vectors (same source, Table 1).
- Large-scale work used about 1 million real voice prompts (https://aclanthology.org/2025.emnlp-main.629.pdf).
- Cloned voices from speakers already in the real data added nothing new (https://huggingface.co/dys-asr/parakeet-tdt-0.6b-syn). Parakeet TDT 0.6B v2 was already trained on VCTK and Common Voice v7 (https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2), so cloning those speakers adds new sentences in voices it has heard, not new voices.

### 1f. Known failure modes

- The model learns cues only generated audio has. Apple's Synt++ names artifacts absent from real data, content errors, unrealistic speaking styles and uneven sampling; separate BatchNorm statistics for real and generated audio plus rejection sampling gave up to 13% relative over naive training (https://arxiv.org/abs/2110.11479).
- BatchNorm mismatch: fix by fusing BatchNorm (https://arxiv.org/abs/2302.14036) or separate statistics (https://arxiv.org/abs/2110.11479).
- Too much generated audio: gains reverse past a share that depends on the setup (https://arxiv.org/html/2411.13159, https://arxiv.org/html/2606.29031v2, https://arxiv.org/pdf/2409.11107).
- Voice engine errors: silences, dropped and repeated words (https://arxiv.org/html/2411.13159). Filter by round-trip recognition: Google dropped clips above 20% WER (https://arxiv.org/abs/1909.11699), Hard-Synth above 10% character error rate.
- Generated audio is too clean: needs room echo and noise (https://arxiv.org/html/2606.29031v2).
- Gains on generated test audio do not carry over: every study above tests on real audio, and generated-only models are 2-5x worse on it.
- Built-in watermarks: Chatterbox and NeuTTS Air stamp an inaudible Perth watermark into every output (https://github.com/resemble-ai/chatterbox, https://huggingface.co/neuphonic/neutts-air). That is a signal present only in generated audio. No paper found measures whether recognisers learn it.

## 2. Free text-to-speech candidates

"Training use" is my reading of the licence for using the audio to train a model Fluidity sells. Not legal advice.

| Model | Voices and English accents | Speed / hardware | Licence and training use |
|---|---|---|---|
| **Kokoro 82M** (in FluidAudio) | 28 English voices: 20 American (11 female, 9 male), 8 British (4, 4). No other English accents (https://huggingface.co/hexgrad/Kokoro-82M/blob/main/VOICES.md). FluidAudio's doc says its English catalogue has 54 voices and names 4 (https://raw.githubusercontent.com/FluidInference/FluidAudio/main/Documentation/TTS/KokoroAne.md). No voice cloning. | Apple Silicon via FluidAudio Core ML: 36-54 ms median per demo input on M5 Pro, excluding text processing; max 510 phonemes per call, no built-in chunking (same doc). Also MLX (https://github.com/Blaizzy/mlx-audio). | Apache-2.0 weights; trained on permissive data (https://huggingface.co/hexgrad/Kokoro-82M). Allowed. |
| **PocketTTS** (Kyutai, in FluidAudio) | 21 English built-in voices plus 5 other-language voices; accents not documented (FluidAudio PocketTTS doc, https://raw.githubusercontent.com/FluidInference/FluidAudio/main/Documentation/TTS/PocketTTS.md). Voice cloning from a 1-30 s clip. | Kyutai: about 6x real time on a MacBook Air M4 CPU, 2 cores, no GPU needed (https://huggingface.co/kyutai/pocket-tts). FluidAudio full v2.1: about 1.8x real time on M-series. | CC-BY-4.0 weights (attribution). Prohibits cloning a voice without the speaker's explicit, lawful consent. Built-in voices have their own licences: `jean` comes from EARS and `cosette` from Expresso, both CC-BY-NC (non-commercial) (https://github.com/kyutai-labs/pocket-tts, https://huggingface.co/kyutai/tts-voices). Allowed with care: avoid NC-sourced voices; clone only consenting speakers. |
| **Phonon 31M** (Gradium, in FluidAudio, released 2026-10-20) | About 100 voices; 25 English named `en_us_*` / `en_gb_*` (US and British only) plus 12 character voices (FluidAudio PocketTTS doc). English only. | About 19-25x real time on M5 Pro (FluidAudio doc). | Apache-2.0 for weights and voices; bars impersonation and non-consensual cloning (https://huggingface.co/Gradium/phonon-31m-en). Allowed. |
| **Chatterbox** (Resemble AI; Turbo 350M, Nano 110M, Multilingual 500M) | Voice cloning from about 10 s; English plus 23+ languages (https://github.com/resemble-ai/chatterbox). | MPS (Apple GPU) example in README; Nano about 3x real time on 8 CPU cores. Also in mlx-audio and FluidAudio (beta). | MIT. Allowed, but every output carries a Perth watermark (see failure modes). |
| **XTTS-v2** (Coqui) | Cloning from a 6 s clip; 17 languages (https://huggingface.co/coqui/XTTS-v2). | README examples use CUDA. | Coqui Public Model License: "Use of the model to train other models for commercial use is not a non-commercial purpose" (https://huggingface.co/coqui/XTTS-v2/blob/main/LICENSE.txt). **Not allowed.** |
| **F5-TTS** | Cloning; Chinese and English base model (https://github.com/SWivid/F5-TTS). | Benchmarks on NVIDIA L20; Apple not mentioned. | Code MIT, weights CC-BY-NC because of Emilia training data. **Not allowed.** |
| **StyleTTS2** | LJSpeech (1 voice) and LibriTTS (multi-speaker) checkpoints (https://github.com/yl4579/StyleTTS2). | Trained on NVIDIA A100; inference on CPU possible; Apple not mentioned. | Code MIT; pretrained-model terms require telling listeners speech is generated and using only voices with permission. Allowed for training data in my reading. Kokoro is the better-packaged choice. |
| **Piper** | en_GB: alan, alba, aru, cori, jenny_dioco, northern_english_male, semaine, southern_english_female, vctk (109 speakers). en_US: 21 voices including libritts_r (904 speakers), arctic, l2arctic (24 non-native speakers) (https://huggingface.co/rhasspy/piper-voices). | CPU. Speed not checked here. | Per voice: vctk and libritts_r are CC-BY-4.0 (allowed); l2arctic is CC-BY-NC (**not allowed**) (model cards in the same repo). Piper says each voice's MODEL_CARD governs (https://github.com/OHF-Voice/piper1-gpl/blob/main/docs/VOICES.md). |
| **Orpheus 3B** (Canopy Labs) | 8 English voices: tara, leah, jess, leo, dan, mia, zac, zoe; emotion tags (https://github.com/canopyai/Orpheus-TTS). | vLLM on GPU; llama.cpp CPU path. Not in mlx-audio list. | Card says Apache-2.0 but the base is Llama-3.2-3B (https://huggingface.co/canopylabs/orpheus-3b-0.1-ft). The Llama 3.2 licence says a model trained with "outputs or results of the Llama Materials" must have a name starting with "Llama" when distributed (https://raw.githubusercontent.com/meta-llama/llama-models/main/models/llama3_2/LICENSE). Unclear; avoid. |
| **Qwen3-TTS** (0.6B, 1.7B; VoiceDesign, CustomVoice, Base) | 10 languages; voices designed from a text description, cloning in Base models; accent control not documented (https://huggingface.co/Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign). | Card examples use CUDA; in mlx-audio for Apple Silicon. | Apache-2.0. Allowed. Used in the banking study above. |
| **Fun-CosyVoice3 0.5B** | Cloning; 9 languages; English accents not listed (https://github.com/FunAudioLLM/CosyVoice). | NVIDIA Docker examples; Apple not mentioned. | Apache-2.0. Allowed. Used in the Parakeet dysarthric card. |
| **Parler-TTS mini v1** | 34 named speakers; prompts control gender, noise, rate, pitch, echo; accent not listed (https://huggingface.co/parler-tts/parler-tts-mini-v1). | CUDA or CPU in examples. | Apache-2.0. Allowed. |
| **NeuTTS Air** | Cloning from 3 s (https://huggingface.co/neuphonic/neutts-air). | GGUF for llama.cpp, CPU. | Apache-2.0, Perth watermark on every output. Allowed. |
| **Magpie TTS Multilingual** (NVIDIA) | 5 English voices: Aria, Jason, Leo, Sofia, John Van Stan (https://huggingface.co/nvidia/magpie_tts_multilingual_357m, per search summary). | NeMo. | NVIDIA Open Model License: commercial use allowed, "NVIDIA claims no ownership rights in outputs" (https://www.nvidia.com/en-us/agreements/enterprise-software/nvidia-open-model-license/). Allowed. |
| **Higgs Audio v3** | Cloning (https://github.com/boson-ai/higgs-audio). | Not stated. | Research and non-commercial licence. **Not allowed.** |

**Getting wider accents.** Kokoro, Phonon and Piper's named voices cover only American and British English. Wider accents need voice cloning from real recordings of accented speakers:
- VCTK: 110 English speakers with various accents, CC-BY-4.0, recorded for voice-cloning research (https://huggingface.co/datasets/CSTR-Edinburgh/vctk). Parakeet has already heard these speakers.
- Common Voice: CC0 with opt-in accent labels; the Mozilla Data Collective datasheets forbid trying to identify speakers and re-sharing (https://datacollective.mozillafoundation.org/datasets/cmko7havo02f5nw07rbwwhowe). Cloning contributors' voices sits awkwardly with the "explicit consent" clauses in PocketTTS and Phonon.
- The owner's own voice: he can consent, and cloning in-domain voices gave the best result in the back-translation study (Table 3 above).

## 3. Text variation and audio augmentation used in published pipelines

**Text**
- Language-model rewriting or sampling of new sentences: Google sampled from a language model and kept sentences under 20 words (https://arxiv.org/abs/1909.11699); Hard-Synth rewrote training texts with a language model (https://arxiv.org/html/2411.13159); Apple generated whole domain corpora (https://arxiv.org/abs/2309.10707).
- Disfluencies: fine-tuned Llama-2 and Flan-T5 models inserting fillers, repetitions and false starts; Bark rendered them most naturally of three engines, but the inserted disfluencies over-generated (https://arxiv.org/html/2412.12710). LLM-Dys found VITS cannot say "um" and "uh" well, used E2-TTS for fillers, and spliced in 0.3-3.5 s silences for pauses (https://arxiv.org/html/2505.22029). No study found measures whether Kokoro or PocketTTS say fillers naturally.
- Number, time and date formats: no study found compares formats for ASR training. The standard tool is NVIDIA's `nemo-text-processing` (Apache-2.0), which converts written forms to spoken forms and back (https://github.com/NVIDIA/NeMo-text-processing). The voice engine reads the spoken form; the training target is the written form Fluidity should output.
- Targeting known errors: the Parakeet dysarthric card wrote 20% of its sentences to target the base model's mistakes (https://huggingface.co/dys-asr/parakeet-tdt-0.6b-syn); Hard-Synth cloned the hardest speakers.
- Quality filter: drop clips a recogniser cannot transcribe back (20% WER, https://arxiv.org/abs/1909.11699; 10% character error rate, https://arxiv.org/html/2411.13159).

**Audio**
- Room echo: real and simulated room impulse responses, the main driver of gains in the banking study (https://arxiv.org/html/2606.29031v2). Free source: OpenSLR 28 room impulse response and noise database, Apache-2.0 (https://www.openslr.org/28/).
- Noise: MUSAN music, speech and noise corpus, CC-BY-4.0 (https://www.openslr.org/17/).
- Speed: copies at 0.9x, 1.0x, 1.1x speed gave 4.3% average relative gain across 4 tasks (Ko et al., https://www.isca-archive.org/interspeech_2015/ko15_interspeech.html).
- Pitch shift, high-pass and low-pass filters: small gains combined with room echo (https://arxiv.org/html/2606.29031v2).
- Masking parts of the spectrogram (SpecAugment): 6.8% test-other WER without a language model on LibriSpeech 960 h (https://arxiv.org/abs/1904.08779). On by default in NeMo configs.
- Microphone and codec simulation: NeMo's `TranscodePerturbation` re-encodes audio through g711, amr-nb or ogg codecs. NeMo also has `SpeedPerturbation`, `TimeStretchPerturbation`, `GainPerturbation`, `ImpulsePerturbation`, `ShiftPerturbation`, `NoisePerturbation`, `WhiteNoisePerturbation`, `RirAndNoisePerturbation` and `SilencePerturbation` (https://raw.githubusercontent.com/NVIDIA/NeMo/main/nemo/collections/asr/parts/preprocessing/perturb.py). No paper found isolates microphone simulation for generated speech.

## 4. Recommended first experiment

The numbers below are my judgment from the sources above, not values any paper tested on Parakeet.

**Split first, and keep the test set clean.**
- Hold out about 40 minutes of the 2 hours of real recordings as the test set, split by recording session. Never use test clips for training, as voice-cloning prompts, or as text for generating variants. Drop any dictation text whose recording is in the test set, and its variants, from generation.
- Also keep one public real test set (for example LibriSpeech test-other) to catch damage to general recognition.

**Voice engines** (all allowed for commercial training, all run on a Mac)
- Kokoro 82M: all 28 English voices.
- PocketTTS (or Phonon): clones of the 109 VCTK speakers, plus the owner's own voice cloned from his training-split recordings. Skip built-in voices sourced from non-commercial sets.
- Leave out Chatterbox and NeuTTS Air in the first round because of the watermark.
- That is about 140 voices. Pick a voice at random per clip, and give the owner's voice about 20% of clips, since he is the main user.

**Text**
- From the ~6,200 texts, generate 2 variants each (numbers and times rewritten, names from the personal word list swapped in, fillers and self-corrections inserted in about a third). Keep the target text in Fluidity's written output form; feed the voice engine the spoken form.
- Decide the target for fillers and "scratch that" before generating. If the app should drop "um", leave it out of the target while the audio contains it. Keep "scratch that" in the target and let the app's cleanup step act on it.

**Amount**
- About 12,400 clips. At an assumed 8 seconds each (not measured; check against the real texts) that is about 28 hours, roughly 20x the real training audio. That is fine because the mix is controlled per batch, not by hours.
- Filter: drop clips that Parakeet transcribes back with more than 20% WER, except where the only errors are on personal-word-list terms (those are the clips meant to teach it).

**Augmentation on generated clips only**
- Room echo from OpenSLR 28 on most clips, MUSAN noise at mixed levels, codec re-encoding on some, speed 0.9-1.1x. NeMo's perturbation classes cover all of these.

**Training arms** (same steps, same learning rate, 3 seeds each)
1. No fine-tuning (current Parakeet).
2. Real only (~80 minutes).
3. Real + generated, 30% of each batch generated.
4. Real + generated, 50% of each batch generated.
5. Same as 4 without echo and noise augmentation (shows whether augmentation carries the gain).

Fuse or freeze BatchNorm before fine-tuning on mixed batches (https://arxiv.org/abs/2302.14036).

**What counts as "it worked"**
- Arm 3 or 4 beats arm 2 on the held-out real dictation by at least 5% relative WER, with a bootstrap 95% confidence interval that excludes zero, across 3 seeds. Published gains with real data present are 4-13% relative, so 5% is a realistic bar.
- Error rate on personal-word-list terms in the held-out set drops at least 25% relative against arm 2. The word-teaching papers saw 57-65%, so 25% is a cautious bar.
- WER on the public real test set rises by no more than 0.5 points absolute.
- If arm 5 matches arm 4, augmentation is not doing the work. If arm 2 matches arms 3 and 4, generated speech adds nothing at this scale and the money is better spent recording more real dictation.

## Could not establish

- Any published, controlled result for Parakeet TDT fine-tuned with generated speech on normal (non-atypical) English. The one public Parakeet result is a self-published model card.
- A gain-against-voice-count curve. No paper varies only the number of voices.
- Whether recognisers learn the Perth watermark in Chatterbox and NeuTTS Air output.
- How well Kokoro and PocketTTS say "um", "uh" and false starts; how well cloning carries a reference speaker's accent in PocketTTS or Phonon.
- The accents of PocketTTS's 21 English built-in voices and the licence of each one beyond the 8 mapped in Kyutai's README.
- Whether NeMo's `ASRWithTTSModel` works with a TDT decoder (docs list CTC, RNN-T and hybrid only).
- Whether the shipped Parakeet checkpoint keeps BatchNorm (only the default FastConformer config was checked).
- Average spoken length of the owner's dictation texts, which sets the real hour count.
