# 03 — What do retraining and hosting cost?

Researched 2026-10-22/23. Prices are on-demand list prices in US dollars, before tax. Every number is tagged with its source and the date seen. Lines marked **estimate** are my arithmetic or assumptions, not a published figure.

## Answer

- **Fine-tuning Parakeet TDT 0.6B is cheap.** One run costs about $2 (10 hours of audio), $7–14 (100 hours) or $28–58 (1,000 hours) on a single rented GPU. Retraining monthly on 1,000 hours, with four attempts per shipped model, comes to roughly $110–230 a month.
- **For the cleanup model, paying per token beats renting GPUs at all three sizes.** At 1,000 / 10,000 / 100,000 users it costs about $20–72 / $200–720 / $2,000–7,200 a month. Dedicated H100s cost about $2,000–4,700 per GPU per month, so 1, 2 and 8 of them come to roughly $2,000–4,700, $3,900–9,500 and $15,700–38,000.
- Dedicated GPUs make sense only when Fluidity needs things per-token hosting doesn't give: its own fine-tuned weights on a provider that won't host them, private deployment (Wispr Flow's stated reason), or control over the slowest requests.
- **Proving-phase ceiling: $500 a month, $1,500 total over three months, and no GPU left running around the clock.** Expected spend is about $250–300 a month. A single forgotten H100 costs about $670 a week.

## 1. Fine-tuning Parakeet TDT 0.6B

### What NVIDIA used

- v2: 150,000 steps on 64 A100s for pretraining. The fine-tune ran 2,500 steps on 4 A100s using about 500 hours of human-transcribed audio. No wall-clock time given. Source: https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2 (seen 2026-10-22).
- v3: 150,000 steps on 128 A100s. The fine-tune ran 5,000 steps on 4 A100s using about 7,500 hours. No wall-clock time given. Source: https://huggingface.co/nvidia/parakeet-tdt-0.6b-v3 (seen 2026-10-22). The paper repeats these numbers and also gives no wall-clock time or batch size: https://arxiv.org/html/2509.14128v1 (seen 2026-10-23).
- A sister model (Japanese Parakeet) states its batch size: "600s per GPU" of audio on 32 A100 80GB GPUs. Source: https://huggingface.co/nvidia/parakeet-tdt_ctc-0.6b-ja (seen 2026-10-23).

So NVIDIA's own fine-tunes used **4 A100s**. Neither NVIDIA source states how many hours they ran.

### The one measured run I found

A community full fine-tune of parakeet-tdt-0.6b-v2 ran 20 epochs (an epoch is one full pass over the training data) at batch size 16 in bf16 on **one L40S, in 41 minutes**. The data was 339.2 + 95.3 + 48.5 = 483 minutes, about 8 hours of audio. Source: https://huggingface.co/danielrosehill/Parakeet-TDT-0.6B-v2-English-Hebrew-Codeswitching (seen 2026-10-23).

Arithmetic: 8.05 h × 20 epochs = 161 hours of audio processed in 0.683 h, so **about 236 hours of audio per GPU-hour on an L40S**. That time includes checking accuracy after each epoch.

### Scaling to other GPUs (estimate)

Dense bf16 compute and memory speed, from NVIDIA's spec pages (seen 2026-10-23):

| GPU | bf16 TFLOPS (dense) | Memory speed | Source |
|---|---|---|---|
| L40S | 362 | 864 GB/s | https://www.nvidia.com/en-us/data-center/l40s/ |
| A100 80GB SXM | 312 | 2,039 GB/s | https://www.nvidia.com/en-us/data-center/a100/ |
| H100 SXM | 989 (page lists 1,979 with sparsity; half that is dense) | 3.35 TB/s | https://www.nvidia.com/en-us/data-center/h100/ |

**Planning numbers (estimate):** 200 hours of audio per GPU-hour on an L40S or A100 (rounded down from the measured 236), and 400 on an H100. The H100 has 2.7× the L40S's compute, but small batches rarely use all of it, so I assume 2×.

**Epoch counts (estimate):** 20 epochs for 10 h, 10 for 100 h, 5 for 1,000 h. This is likely generous. If NVIDIA's v2 fine-tune used the Japanese model's 600 s per GPU, then 2,500 steps × 4 GPUs × 600 s = 1,667 hours of audio, only about 3.3 passes over its 500 hours.

**Overhead (estimate):** add 1 GPU-hour per run for downloading the model, loading data, a final accuracy test and saving.

### Rental prices

| GPU | RunPod Community | RunPod Secure | Lambda | Source |
|---|---|---|---|---|
| L40S 48GB | $0.79/h | $1.09/h | not listed | https://www.runpod.io/pricing (seen 2026-10-22) |
| A100 SXM 80GB | $1.39/h | $1.79/h | $2.79/h | RunPod as above; https://lambda.ai/pricing (seen 2026-10-22) |
| H100 SXM 80GB | $2.69/h | $3.99/h | $3.99–4.29/h | as above |
| H100 PCIe 80GB | $1.99/h | $2.89/h | $3.29/h | as above |

RunPod "Community Cloud" runs on third-party hosts. "Secure Cloud" runs in vetted data centres. For user audio, assume Secure.

### Cost per run (estimate)

| Audio | Hours processed | L40S GPU-hours | L40S cost (RunPod Secure $1.09) | H100 GPU-hours | H100 cost ($2.69–4.29) |
|---|---|---|---|---|---|
| 10 h | 10 × 20 = 200 | 200/200 + 1 = 2 | $2.18 | 200/400 + 1 = 1.5 | $4.04–6.44 |
| 100 h | 100 × 10 = 1,000 | 1,000/200 + 1 = 6 | $6.54 | 1,000/400 + 1 = 3.5 | $9.42–15.02 |
| 1,000 h | 1,000 × 5 = 5,000 | 5,000/200 + 1 = 26 | $28.34 | 5,000/400 + 1 = 13.5 | $36.32–57.92 |

On 8 H100s the 1,000-hour run finishes in under 2 hours of wall time for roughly the same total GPU-hours. Splitting across GPUs adds a little waste, but NVIDIA used 4 GPUs for its own fine-tunes.

### Monthly retraining (estimate)

Assume one shipped model a month, built on 1,000 hours of audio, with 4 attempts per shipped model (settings that don't work out, reruns):

- L40S: 26 h × 4 = 104 GPU-hours × $1.09 = **$113 a month**.
- H100: 13.5 h × 4 = 54 GPU-hours × $3.99–4.29 = **$215–232 a month**.

Storage: 1,000 hours of 16 kHz, 16-bit mono audio is 32,000 bytes/s × 3,600,000 s ≈ 115 GB. I did not check storage prices.

## 2. Serving the cleanup model (about 8B parameters)

### Target speed

Wispr Flow: "the Llama model must consistently process and generate 100+ tokens in under 250 milliseconds", measured at p99 (the slowest 1 in 100 requests), with "under 700 milliseconds" end to end. They built it with "Baseten's TensorRT-LLM engine builder for fine-tuned Llama models". The case study names no GPU, model size or user count, and **does not mention speculative decoding** (a technique where a small draft model guesses several tokens and the main model checks them in one pass). Source: https://www.baseten.co/resources/customers/wispr-flow/ (seen 2026-10-23). It also says private, dedicated deployment was a requirement for handling sensitive user data.

100 tokens in 250 ms needs at least **400 output tokens per second per request**. Fluidity's ~40-token outputs need only 160 tokens/s to finish in 250 ms.

### What one GPU does (published)

- Llama 3.1 8B in FP8 (8-bit numbers) with TensorRT-LLM, 128 tokens in and 128 out, maximum load: **26,401 output tokens/s on one H100**, 27,028 on H200. Source: https://nvidia.github.io/TensorRT-LLM/performance/perf-overview.html (page updated 2025-09-15, seen 2026-10-23).
- The same model at 128 in / 128 out serves "up to ~300" tokens/s to a single user. At 512 users at once it serves about 66 tokens/s each, about 25,000 tokens/s in total. The post doesn't name the GPU. Source: https://developer.nvidia.com/blog/llm-inference-benchmarking-performance-tuning-with-tensorrt-llm/ (posted 2025-07-07, seen 2026-10-23).
- Speculative decoding (Medusa) gave "up to 1.9x" higher per-user speed on H200 for Llama 3.1 70B and 405B. Source: https://developer.nvidia.com/blog/low-latency-inference-chapter-1-up-to-1-9x-higher-llama-3-1-performance-with-medusa-on-nvidia-hgx-h200-with-nvlink-switch/ (seen via search 2026-10-23).

What this means:

- One H100 at about 300 tokens/s per user delivers 100 tokens in about 333 ms. That misses Wispr's 250 ms without speculative decoding. With about 1.9×, it reaches about 570 tokens/s, or 175 ms.
- For Fluidity's 40 tokens, 40 / 300 ≈ 133 ms, which fits **without** speculative decoding.
- Writing each token means reading every model weight from memory once. 8B weights in FP8 are about 8 GB:
  - L40S: 864 GB/s ÷ 8 GB ≈ 108 tokens/s at best.
  - A100 (no FP8 support, so 16 GB of weights at FP16): 2,039 ÷ 16 ≈ 127 tokens/s.
  - H100: 3,350 ÷ 8 ≈ 419 tokens/s, which matches the measured ~300.
  - **So for this latency, plan on H100-class GPUs or newer.**

### Load assumptions (estimate)

- 50 dictations × 40 output tokens = 2,000 output tokens per user per day.
- Input: about 200 tokens per dictation (cleanup instructions plus the raw transcript), so 10,000 input tokens per user per day. Input is the larger cost, so shrinking the instructions or caching them matters.
- 30-day month: 60,000 output and 300,000 input tokens per user.
- Busiest time: all 50 dictations fall in an 8-hour working day, the busiest moment runs at twice that average, and all users are in one time zone (worst case).

| Users | Output tokens/month | Input tokens/month | Requests/s at busiest | Output tokens/s at busiest | Requests in progress at once (0.2 s each) |
|---|---|---|---|---|---|
| 1,000 | 60 M | 300 M | 3.5 | 139 | 0.7 |
| 10,000 | 600 M | 3 B | 35 | 1,389 | 7 |
| 100,000 | 6 B | 30 B | 347 | 13,889 | 69 |

Busiest requests/s = users × 50 / (8 × 3,600) × 2.

### Paying per token

| Provider | Model and price per 1M tokens (in / out) | 1,000 users | 10,000 users | 100,000 users | Source |
|---|---|---|---|---|---|
| Groq | Llama 3.1 8B Instant, $0.05 / $0.08, ~750 tokens/s | $19.80 | $198 | $1,980 | https://groq.com/pricing (the live page didn't render for me; figures come from a search-engine copy of that page, seen 2026-10-23) |
| Cerebras | llama3.1-8b, $0.10 / $0.10 | $36 | $360 | $3,600 | **Secondary source only**: https://futureagi.com/llm-cost-calculator/cerebras/llama3-1-8b (checked by them 2026-05-12). Cerebras' own model list no longer shows an 8B model: https://inference-docs.cerebras.ai/models/overview (seen 2026-10-23). Treat as possibly withdrawn. |
| Together | Llama 3 8B Instruct Lite, $0.14 / $0.14 (no Llama 3.1 8B listed) | $50.40 | $504 | $5,040 | https://www.together.ai/pricing (seen 2026-10-22) |
| Fireworks | 4B–16B size tier, $0.20 in and out | $72 | $720 | $7,200 | https://docs.fireworks.ai/serverless/pricing (seen 2026-10-23) |

Example (Groq, 1,000 users): 300 M × $0.05 + 60 M × $0.08 = $15 + $4.80 = $19.80.

**The catch:** these prices are for the provider's own copy of the model. Hosting Fluidity's own fine-tuned weights may need a different product or price. I did not confirm which of these four will host a customer's fine-tune per token.

### Dedicated GPUs

Monthly cost = hourly price × 730 hours, for an H100 left on all month:

| Where | $/hour | $/month | Source |
|---|---|---|---|
| RunPod Community H100 SXM | $2.69 | $1,964 | https://www.runpod.io/pricing (2026-10-22) |
| RunPod Secure H100 SXM | $3.99 | $2,913 | same |
| Lambda H100 SXM | $3.99–4.29 | $2,913–3,132 | https://lambda.ai/pricing (2026-10-22) |
| Together dedicated H100 | $5.49 | $4,008 | https://www.together.ai/pricing (2026-10-22) |
| Baseten H100 | $6.50 ($0.10833/min) | $4,745 | https://www.baseten.co/pricing/ (2026-10-23) |
| Baseten H100 half-GPU partition (40 GB) | $3.75 | $2,738 | same |
| Fireworks H100 | $8.00 | $5,840 | https://fireworks.ai/pricing (2026-10-23) |

RunPod and Lambda rent a bare machine, so Fluidity runs the serving software itself. Baseten, Together and Fireworks run it for you. Baseten scales by the minute, which is how Wispr Flow avoids paying for idle GPUs.

**GPUs needed (estimate):** I assume one H100 keeps each request at 200+ tokens/s up to about 2,000 output tokens/s in total. The NVIDIA post shows its speed-versus-users curve only as a chart, so this number needs a benchmark of our own. I add one spare GPU for failover once there are paying users.

| Users | GPUs | $/month (always on, $1,964–4,745 per GPU) | Per-token range from the table above |
|---|---|---|---|
| 1,000 | 1 (139 tokens/s at busiest) | $1,964–4,745 | $20–72 |
| 10,000 | 1 + 1 spare (1,389 tokens/s) | $3,928–9,490 | $198–720 |
| 100,000 | 7 + 1 spare (13,889 / 2,000 = 7) | $15,712–37,960 | $1,980–7,200 |

Scaling down overnight and at weekends would cut the 100,000-user dedicated cost by up to about half. It would still cost more than paying per token.

**Where they cross (estimate):** at Fireworks' $0.20, one RunPod Secure H100 ($2,913) buys 14.6 B tokens a month. That is about 40,000 users at 360,000 tokens each. But 40,000 users need about 3 GPUs at the busiest time, so per-token stays cheaper at every size in this table.

### Fine-tuning the cleanup model itself (for completeness)

- Together: $0.34–0.38 per 1M training tokens for Llama 3.1 8B, $4 minimum. Source: https://www.together.ai/pricing (2026-10-22).
- Fireworks: $0.50 per 1M for LoRA (training a small add-on to the model rather than all its weights), $1.00 per 1M for full training. Source: https://fireworks.ai/pricing (2026-10-23).
- Example (estimate): 100,000 examples × 300 tokens × 3 epochs = 90 M tokens, so $31–45 per run.

## 3. Proving-phase spending ceiling

**Proposal: $500 a month hard cap, $1,500 total for a three-month proving phase.**

Expected spend (estimate):

| Item | Assumption | $/month |
|---|---|---|
| Parakeet experiments | 15 runs at 10–100 h (about 6 L40S-hours each) plus 2 runs at 1,000 h, at $1.09/h | 15 × 6 × 1.09 + 2 × 26 × 1.09 ≈ $155 |
| Cleanup-model fine-tunes | 3 runs at $31–45 | $93–135 |
| Testing cleanup through a per-token provider | a few million tokens | under $5 |
| Storage | ~115 GB per 1,000 hours of audio | not checked |
| **Total** | | **about $250–300** |

Why $500:

- It leaves about 1.7× headroom over the expected spend, enough for a bad month of reruns or one H100 day of experiments (24 h × $3.99 = $96).
- It rules out the one thing that breaks the budget: a dedicated inference GPU. One always-on H100 costs $1,964–4,745 a month, 4–9× the cap, and buys nothing with no users. Use per-token hosting until there are users.
- The likeliest overspend is a rented GPU left running after a run: one H100 for a week is 168 × $3.99 = $670. Shut machines down when each run ends and check the provider dashboard weekly.

Raise the cap only when a specific milestone needs it, for example the first 1,000-hour model trained on crowdsourced data, or a latency test of the cleanup model on dedicated hardware (a few hours of H100 at $3–6.50/h).

## Could not establish

- The wall-clock time of NVIDIA's own Parakeet fine-tunes. The fine-tune hours above rest on one community run on an L40S plus GPU spec ratios. Benchmark 200 steps on our own data before trusting them.
- How many users one H100 can serve while keeping each request at 200+ tokens/s. NVIDIA publishes this only as a chart.
- Whether Groq, Cerebras, Together or Fireworks will host a customer's fine-tuned 8B model per token, and at what price.
- Groq's live pricing page (it didn't render; numbers come from a search-engine copy of that page) and Cerebras' current 8B price (its own docs no longer list the model).
- Whether Wispr Flow uses speculative decoding. The Baseten case study names TensorRT-LLM only.
- Storage and data-transfer prices.
