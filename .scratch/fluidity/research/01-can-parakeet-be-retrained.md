# 01: Can Parakeet models be retrained on new data?

Researched 2026-10-23. Scope: general retraining of NVIDIA Parakeet speech-to-text models and the general route back to Core ML. The specific FluidInference Core ML builds on Hugging Face are covered by a separate ticket.

## Answer

Yes. Every Parakeet variant (TDT, CTC, RNNT, and the streaming end-of-utterance model) is a NeMo model, and NVIDIA's own docs show fine-tuning `parakeet-tdt-0.6b-v2` with one script and a list of audio/transcript pairs. A few hours of English on one rented GPU is enough to move accuracy on a narrow domain; one published full fine-tune used 8.1 hours of audio, ran 41 minutes on one GPU, and cut word error rate on its target speech from 11.3% to 5.1% without hurting LibriSpeech. The retrained model goes back through the same tracing-and-conversion script FluidInference uses for the stock model, because that script accepts a local `.nemo` file.

The main risk on small data is overfitting to the new speech and forgetting general English. The published mitigations are a low learning rate, mixing in some original-style English, and checking a general benchmark before and after. Two cheaper options exist: small add-on layers trained on a frozen model ("adapters" in NeMo's terms), and boosting a phrase list at decode time with no training at all.

Terms used below:
- **Word error rate (WER):** the share of words the model gets wrong. Lower is better.
- **Fine-tuning:** continuing training of an already-trained model on new data.
- **NeMo:** NVIDIA's open-source training toolkit that Parakeet is built and published with.
- **`.nemo` file:** NeMo's single-file package holding a model's weights, config and tokenizer.
- **Tokenizer:** the fixed list of word pieces the model can output (1,024 or 8,192 pieces depending on model).

## 1. The models

| Model | Size | Decoder | Training data | License |
|---|---|---|---|---|
| `parakeet-tdt-0.6b-v2` | 600M parameters | TDT (predicts each word piece plus how many audio frames to skip) | ~120,000 h English, of which ~110,000 h machine-labelled | CC-BY-4.0 |
| `parakeet-tdt-0.6b-v3` | 600M | TDT | 10,000 h human-labelled + 660,000 h machine-labelled, 25 European languages | CC-BY-4.0 |
| `parakeet_realtime_eou_120m-v1` | 120M | RNNT, streaming, emits an `<EOU>` end-of-utterance token | Granary, NeMo ASR Set 3.0, some text-to-speech audio | NVIDIA Open Model License |

Sources: [v2 card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2), [v3 card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3), [EOU card](https://huggingface.co/nvidia/parakeet_realtime_eou_120m-v1).

How NVIDIA trained them, as a scale reference:
- v2: stage 1 was 150,000 steps on 64 A100 GPUs; stage 2 was 2,500 steps on 4 A100s using ~500 h of human-transcribed data ([v2 card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2)).
- v3: stage 1 was 150,000 steps on 128 A100s; stage 2 was 5,000 steps on 4 A100s using ~7,500 h ([v3 card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3)).
- Neither card gives wall-clock time.
- Both cards state the checkpoint "can be used for fine-tuning on another dataset" and link NeMo's training script and TDT config ([v2 card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2)).
- The EOU card gives no fine-tuning instructions ([EOU card](https://huggingface.co/nvidia/parakeet_realtime_eou_120m-v1)).

Baseline accuracy to beat: v2 averages 6.05% WER on the Hugging Face Open ASR Leaderboard sets, 1.69% on LibriSpeech test-clean, 11.16% on AMI meetings ([v2 card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2)). v3 averages 6.34% on the same sets ([v3 card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3)).

## 2. Tooling

### NeMo (the supported path)

- Entry point: `examples/asr/speech_to_text_finetune.py` with config `examples/asr/conf/asr_finetune/speech_to_text_finetune.yaml` ([NeMo fine-tuning docs](https://docs.nvidia.com/nemo/speech/latest/asr/fine_tuning.html)).
- NVIDIA's own example command starts from Parakeet v2:
  ```
  python examples/asr/speech_to_text_finetune.py \
      --config-path=../conf/asr_finetune \
      --config-name=speech_to_text_finetune \
      init_from_pretrained_model="nvidia/parakeet-tdt-0.6b-v2" \
      model.train_ds.manifest_filepath=/path/to/train_manifest.json \
      model.validation_ds.manifest_filepath=/path/to/val_manifest.json \
      trainer.devices=1 \
      trainer.max_epochs=50
  ```
  ([NeMo fine-tuning docs](https://docs.nvidia.com/nemo/speech/latest/asr/fine_tuning.html))
- Start from a hub name (`init_from_pretrained_model`) or a local file (`init_from_nemo_model`) ([NeMo fine-tuning docs](https://docs.nvidia.com/nemo/speech/latest/asr/fine_tuning.html)).
- Keeping the tokenizer: "No special handling needed — fine-tune directly." Changing it means resetting the decoder and joint network, which throws away much of what the model learned about text ([NeMo fine-tuning docs](https://docs.nvidia.com/nemo/speech/latest/asr/fine_tuning.html)). For English dictation, keep the tokenizer.
- Recommended settings: 50–100 epochs for domain adaptation; learning rate "lower than training from scratch, e.g., 1e-4 to 1e-5"; replace the warm-up schedule (Noam) with constant or cosine so the learning rate doesn't jump high again ([NeMo fine-tuning docs](https://docs.nvidia.com/nemo/speech/latest/asr/fine_tuning.html)).
- Partial loading (`include` / `exclude` lists) lets you keep the encoder and reset other parts ([NeMo config docs](https://docs.nvidia.com/nemo-framework/user-guide/latest/nemotoolkit/asr/configs.html)).
- A Hugging Face datasets variant exists, `speech_to_text_finetune_with_hf.py`, but it does not work with NeMo's Lhotse data loader, which the docs recommend for efficient batching ([NeMo fine-tuning docs](https://docs.nvidia.com/nemo/speech/latest/asr/fine_tuning.html)).

### Hugging Face Transformers (second option)

- Transformers has `ParakeetForCTC`, `ParakeetForRNNT` and `ParakeetForTDT`, and its docs show a training step (loss computed, `backward()` called) for each ([Transformers Parakeet docs, main branch](https://huggingface.co/docs/transformers/main/en/model_doc/parakeet)).
- The v3 card carries the same Transformers training snippet ([v3 card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3)).
- Not established: whether a model fine-tuned in Transformers converts back to a `.nemo` file that the Core ML converter in section 7 accepts. The converter loads `.nemo` files only (section 7). This is the reason to prefer NeMo.

## 3. Data format

- One JSON object per line ("manifest"), with `audio_filepath`, `text` and `duration` in seconds ([NeMo dataset docs](https://docs.nvidia.com/nemo-framework/user-guide/latest/nemotoolkit/asr/datasets.html)):
  ```json
  {"audio_filepath": "/path/to/audio.wav", "text": "the transcription of the utterance", "duration": 23.147}
  ```
- Audio: 16 kHz mono WAV or FLAC ([v2 card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2)). NeMo reads anything Pydub reads but recommends WAV ([NeMo dataset docs](https://docs.nvidia.com/nemo-framework/user-guide/latest/nemotoolkit/asr/datasets.html)).
- Separate training and validation manifests ([NeMo dataset docs](https://docs.nvidia.com/nemo-framework/user-guide/latest/nemotoolkit/asr/datasets.html)).
- For hundreds of hours, NeMo can read audio packed into tar files ("tarred datasets") to avoid opening millions of small files; don't use them for validation ([NeMo dataset docs](https://docs.nvidia.com/nemo-framework/user-guide/latest/nemotoolkit/asr/datasets.html)).
- Transcripts must match the model's output style. v2 outputs punctuation and capitals ([v2 card](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2)), so training text should too, or the model will learn to drop them. (My inference from how training works; not stated by NVIDIA.)
- Every character in the new transcripts must exist in the tokenizer. If not, a SentencePiece model learns to emit `⁇` ([NeMo adapters tutorial](https://github.com/NVIDIA-NeMo/Speech/blob/main/tutorials/asr/asr_adapters/ASR_with_Adapters.ipynb)).

## 4. Hardware and run time

No NVIDIA document gives memory or time for fine-tuning Parakeet. Published runs by others:

| Run | Data | Method | Hardware | Time |
|---|---|---|---|---|
| English–Hebrew dictation, one speaker | 8.1 h (339 min code-switched + 95 min own English + 49 min LibriSpeech) | Full fine-tune of v2, NeMo 2.7.3, lr 3e-5, 20 epochs, batch 16, bf16 | 1× NVIDIA L40S (48 GB) | 41 min total |
| Huntington's disease speech | 4.5 h corpus, 70% used for training | Encoder adapters on frozen v2, lr 3e-4, 8 epochs | 2× NVIDIA H200 | not stated |
| Hindi (failed run) | ~100 h | v2 with encoder frozen (~9M of 617M parameters trained), batch 4 | 1× P100 16 GB, ~11 GB used | ~56 min per epoch |

Sources: [Hebrew fine-tune card](https://huggingface.co/danielrosehill/Parakeet-TDT-0.6B-v2-English-Hebrew-Codeswitching), [Huntington's paper, arXiv 2603.11168](https://arxiv.org/abs/2603.11168), [v2 discussion #47](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2/discussions/47).

Read-across for Fluidity: a few hours of English fits in under an hour on one 48 GB rented GPU. 200–500 hours is 25–60× the Hebrew run's data, which at the same settings is roughly 17–41 hours on one such GPU, or proportionally less on several. (My extrapolation from the table, not a measured figure.) Every run found used NVIDIA GPUs; none trained on Apple Silicon.

## 5. Risks

- **Forgetting general English.** NVIDIA's adapters tutorial says that training the whole model, or even just the decoder, "severely degrade[s] the model's performance on the original dataset" ([NeMo adapters tutorial](https://github.com/NVIDIA-NeMo/Speech/blob/main/tutorials/asr/asr_adapters/ASR_with_Adapters.ipynb)). NeMo's fine-tuning docs warn that "too high a learning rate can destroy pretrained features" ([NeMo fine-tuning docs](https://docs.nvidia.com/nemo/speech/latest/asr/fine_tuning.html)).
- **Measured mitigation.** The Hebrew run mixed in LibriSpeech and the speaker's own English (~30% English overall) and used lr 3e-5. LibriSpeech test-clean stayed at 1.20% → 1.23% WER ([Hebrew fine-tune card](https://huggingface.co/danielrosehill/Parakeet-TDT-0.6B-v2-English-Hebrew-Codeswitching)).
- **NVIDIA's own version of the same fix.** For the v3/Canary final training stage, NVIDIA moved data sampling weights gradually instead of all at once, and reported this kept the model better on spontaneous speech than training only on clean data ([Canary-1B-v2 & Parakeet-TDT-0.6B-v3 paper](https://arxiv.org/html/2509.14128v1)).
- **Overfitting on small data.** Adapters make it "trivial to rapidly overfit these datasets and significantly degrade performance on the original domain"; NVIDIA suggests starting at 1–5 epochs over the new data and adjusting ([NeMo adapters tutorial](https://github.com/NVIDIA-NeMo/Speech/blob/main/tutorials/asr/asr_adapters/ASR_with_Adapters.ipynb)).
- **Words never heard in training don't improve.** In the Hebrew run, terms present in the training audio went from 27.7% to 72.7% correct; held-out terms gained far less and the author calls the last round's gain "within noise" ([Hebrew fine-tune card](https://huggingface.co/danielrosehill/Parakeet-TDT-0.6B-v2-English-Hebrew-Codeswitching)).
- **One speaker in, one speaker tested.** The Hebrew results use a single voice for train and test, so they say nothing about other users ([Hebrew fine-tune card](https://huggingface.co/danielrosehill/Parakeet-TDT-0.6B-v2-English-Hebrew-Codeswitching)). Crowdsourced data from many users avoids this but adds noisier labels.
- **New language with ~100 h failed.** Hindi and Chinese runs with ~100 h gave very poor WER; no fix was found in the thread ([v2 discussion #47](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2/discussions/47)). This does not apply to English dictation, which the tokenizer already covers.

## 6. Published fine-tunes and reported gains

| Work | Base | Data | Before → after WER | General English after |
|---|---|---|---|---|
| English–Hebrew code-switching | v2, full fine-tune | 8.1 h, one speaker | 11.3% → 5.1% (held-out split); long-form 9.6% → 5.0%; own English 3.1% → 1.7% | LibriSpeech clean 1.20% → 1.23% |
| Huntington's disease speech | v2, encoder adapters, frozen base | ~3 h training split | 6.99% → 4.95% | not measured |
| NVIDIA v3 final stage (rebalancing, not new domain) | Canary-1B-v2 | 15,000 h subset | 11.03% → 8.40% on FLEURS | n/a |

Sources: [Hebrew fine-tune card](https://huggingface.co/danielrosehill/Parakeet-TDT-0.6B-v2-English-Hebrew-Codeswitching), [Huntington's paper](https://arxiv.org/abs/2603.11168), [Canary-1B-v2 & Parakeet-TDT-0.6B-v3 paper](https://arxiv.org/html/2509.14128v1).

The Huntington's paper also reports v2 out of the box at 6.99% on that speech versus Whisper-large-v2 at 18.44% ([Huntington's paper](https://arxiv.org/abs/2603.11168)). I found no NVIDIA-published before/after numbers for a customer domain fine-tune of Parakeet.

## 7. Alternatives to full fine-tuning

### Adapters (NeMo built-in)

- Small extra layers added to each encoder block; the base model is frozen and only the adapters train. They add "generally 0.5% - 1%" of the model's parameters, start out contributing zero, and can be switched off to get the original model back exactly ([NeMo adapters tutorial](https://github.com/NVIDIA-NeMo/Speech/blob/main/tutorials/asr/asr_adapters/ASR_with_Adapters.ipynb)).
- NVIDIA's tutorial adapts on under 1 hour of data, "on a single GPU, in around 10 minutes of training time" ([NeMo adapters tutorial](https://github.com/NVIDIA-NeMo/Speech/blob/main/tutorials/asr/asr_adapters/ASR_with_Adapters.ipynb)).
- Types available for ASR: `linear` (`LinearAdapter`) and `tiny_attn` (`RelPositionMultiHeadAttentionAdapter`) ([asr_adaptation.yaml](https://github.com/NVIDIA-NeMo/Speech/blob/main/examples/asr/conf/asr_adapters/asr_adaptation.yaml)). Script: `examples/asr/asr_adapters/train_asr_adapter.py` ([script](https://github.com/NVIDIA-NeMo/Speech/blob/main/examples/asr/asr_adapters/train_asr_adapter.py)).
- Limits: the decoder stays frozen, so the model doesn't learn new word patterns from the text; the tokenizer can't change ([NeMo adapters tutorial](https://github.com/NVIDIA-NeMo/Speech/blob/main/tutorials/asr/asr_adapters/ASR_with_Adapters.ipynb)).
- Shown working on Parakeet-TDT 0.6B v2 by the Huntington's paper above.
- The tutorial notes adapters allow one shared model with a small personal adapter per user ([NeMo adapters tutorial](https://github.com/NVIDIA-NeMo/Speech/blob/main/tutorials/asr/asr_adapters/ASR_with_Adapters.ipynb)).

### LoRA

- LoRA (low-rank adaptation: two small matrices added beside a layer's weights) is not one of NeMo's ASR adapter types. In the NeMo Speech repo, LoRA code lives only under `speechlm2` (speech language models), via Hugging Face PEFT (`nemo/collections/speechlm2/parts/lora.py`, found by GitHub code search of [NVIDIA-NeMo/Speech](https://github.com/NVIDIA-NeMo/Speech)).
- Not established: any published LoRA fine-tune of Parakeet. Applying PEFT to the Transformers `ParakeetFor*` classes is plausible but I found no source doing it.

### Decode-time phrase boosting (no training)

- NeMo's GPU phrase boosting works on CTC, RNNT and TDT decoding, greedy or beam, and "is applied only at the decoding step", so the model isn't retrained. Input is a phrase list. For v2, phrases must be written with capitals because the model outputs capitals ([NeMo word boosting docs](https://docs.nvidia.com/nemo/speech/latest/asr/asr_customization/word_boosting.html)).
- Per-utterance phrase lists are supported for greedy RNNT/TDT decoding ([NeMo word boosting docs](https://docs.nvidia.com/nemo/speech/latest/asr/asr_customization/word_boosting.html)).
- The paper claims it beats open-source alternatives in accuracy and speed with up to 20,000 phrases "without noticeable speed degradation" ([GPU-PB paper, arXiv 2508.07014](https://arxiv.org/abs/2508.07014)). Neither the docs page nor the abstract gives WER numbers.
- Two older options: CTC word spotting (`CTC-WS`, needs a CTC head) and Flashlight word boosting (CTC with a KenLM language model) ([NeMo word boosting docs](https://docs.nvidia.com/nemo/speech/latest/asr/asr_customization/word_boosting.html)).
- This is NeMo's Python decoding code. Running it inside a Core ML app means reimplementing it in the app's decoding loop. (Inference; the docs only cover NeMo.)

## 8. Getting a retrained model back onto the Apple Neural Engine

General route, using Fluid Inference's möbius repo ([mobius](https://github.com/FluidInference/mobius), Apache-2.0):

1. **Export from NeMo.** `convert-parakeet.py convert --nemo-path /path/to/model.nemo --output-dir ./build` ([möbius conversion docs](https://docs.fluidinference.com/mobius/converting-models.md)). The v2 script loads the file with `EncDecRNNTBPEModel.restore_from(nemo_path)` and falls back to downloading `nvidia/parakeet-tdt-0.6b-v2` only when no path is given ([convert-parakeet.py, v2](https://github.com/FluidInference/mobius/blob/main/models/stt/parakeet-tdt-v2-0.6b/coreml/convert-parakeet.py)). A fine-tuned `.nemo` with the same architecture goes through the same path.
2. **Split and trace.** The script wraps the preprocessor, encoder, decoder and joint network separately, traces each with `torch.jit.trace`, converts with coremltools, and saves `parakeet_preprocessor`, `parakeet_encoder`, `parakeet_mel_encoder`, `parakeet_decoder`, `parakeet_joint`, `parakeet_joint_decision` and `parakeet_joint_decision_single_step` `.mlpackage` files ([convert-parakeet.py, v2](https://github.com/FluidInference/mobius/blob/main/models/stt/parakeet-tdt-v2-0.6b/coreml/convert-parakeet.py)).
3. **Fixed input length.** Core ML needs fixed shapes; Parakeet TDT is exported at 15 s of 16 kHz audio (240,000 samples), the EOU model at 320 ms ([möbius conversion docs](https://docs.fluidinference.com/mobius/converting-models.md)).
4. **Precision and hardware.** Export defaults to FLOAT32 with a FLOAT16 option; tracing runs CPU-only for repeatable results; the compute unit (`.cpuAndNeuralEngine`, `.all`) is chosen when the app loads the model; minimum macOS 14 / iOS 17 ([convert-parakeet.py, v2](https://github.com/FluidInference/mobius/blob/main/models/stt/parakeet-tdt-v2-0.6b/coreml/convert-parakeet.py), [möbius conversion docs](https://docs.fluidinference.com/mobius/converting-models.md)). Apple's docs say a model typed in float32 is barred from the Neural Engine, and that coremltools types ML programs in float16 by default ([coremltools typed execution](https://apple.github.io/coremltools/docs-guides/source/typed-execution.html)). Which möbius parts end up on the Neural Engine at FLOAT32 export is not stated in its docs.
5. **Check against PyTorch.** `compare-components.py compare` runs both on the same input and reports error and speed per part; the published v3 encoder result is 1,030 ms on PyTorch CPU vs 25 ms on Core ML with the Neural Engine ([möbius conversion docs](https://docs.fluidinference.com/mobius/converting-models.md)).
6. **Optional shrinking.** `quantize_coreml.py` tries 8-bit per-channel (~2× smaller, "minimal loss") and 6-bit palettization (~2.5×) ([möbius conversion docs](https://docs.fluidinference.com/mobius/converting-models.md)).

möbius has folders for `parakeet-tdt-v2-0.6b`, `parakeet-tdt-v3-0.6b`, `parakeet-tdt-ctc-110m`, `parakeet-realtime-eou-120m` and others under `models/stt/` ([mobius repo](https://github.com/FluidInference/mobius/tree/main/models/stt)).

Things that break the drop-in path:
- **A changed tokenizer.** The script reads the vocabulary size from the model ([convert-parakeet.py, v2](https://github.com/FluidInference/mobius/blob/main/models/stt/parakeet-tdt-v2-0.6b/coreml/convert-parakeet.py)), so the app's vocabulary file would also need replacing. Keeping the tokenizer avoids this.
- **Adapters.** An adapter model swaps the encoder class for an adapter-enabled subclass ([NeMo adapters tutorial](https://github.com/NVIDIA-NeMo/Speech/blob/main/tutorials/asr/asr_adapters/ASR_with_Adapters.ipynb)). Not established: whether möbius traces that class cleanly. The linear adapter is LayerNorm + two linear layers + an activation ([NeMo adapters tutorial](https://github.com/NVIDIA-NeMo/Speech/blob/main/tutorials/asr/asr_adapters/ASR_with_Adapters.ipynb)), all ordinary operations, so it's likely, but untested. Because of the activation, an adapter can't be folded into the base weights; the shipped encoder would carry it.

## Could not establish

- Memory and run-time figures from NVIDIA for fine-tuning Parakeet; only third-party runs exist.
- Any NVIDIA-published before/after WER for a domain fine-tune of Parakeet.
- Any published LoRA fine-tune of Parakeet.
- WER gains from GPU phrase boosting (the paper body wasn't read; the abstract and docs give none).
- Whether a Transformers-trained Parakeet converts back to `.nemo`.
- Whether möbius converts an adapter-enabled encoder without changes.
- Fine-tuning guidance specific to the 120M end-of-utterance model.
