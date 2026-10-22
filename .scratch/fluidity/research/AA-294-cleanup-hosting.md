# AA-294: Can Alec host the cleanup model himself instead of paying a service?

Researched 2026-10-23. Every web source was read on 2026-10-23 unless a row says otherwise. Prices are list prices before tax.

## Answer

At 1 to 10 users, owning the setup does not pay on cost. A per-token service costs pennies to a few dollars a month. The cheapest owned GPU that stays warm costs about $117 to $200 a month. The cheapest owned option that stays inside the 250 ms target is a scale-to-zero GPU on Modal that the app starts as soon as the user begins recording. That comes to about $5 a month for 1 user (inside Modal's $30 free credit) and about $47 to $54 a month for 10. Its cold start has not been measured.

Owning only earns its place for two reasons:

1. Privacy. Dictation text never reaches a third party when it runs on Alec's own Mac.
2. Serving a 0.8B fine-tune. No per-token service I found accepts a custom fine-tune of a model that small. The ones that take your own LoRA (a small add-on weight file that adjusts a base model) start at 8B base models, or older 2B-7B models on Cloudflare.

Licence blocker: Fluid-1 Pico's own terms forbid hosting it anywhere outside ALTIC's FluidVoice apps, and forbid using it in any third-party app (details in the next section). Whichever option wins, Alec needs his own fine-tune of the Apache-2.0 base model `Qwen/Qwen3.5-0.8B`.

Recommended order:

1. Make local cleanup faster first. It costs nothing and is the most private. Alec's 608 ms on the M1 sits close to what that chip can physically do without speculative decoding, so speculative decoding plus caching the fixed instruction text is where the speed must come from.
2. If a server is still needed, run a 0.8B model on Modal serverless, pinned to a European region, with the app starting the container when recording begins.
3. Do not self-host an 8B model. Reaching 250 ms needs an H100-class card plus speculative decoding, at about $2,900 a month or more. Use a per-token service for that size.

## Licence finding: Fluid-1 Pico cannot be self-hosted

- `altic-dev/Fluid-1-Pico-0.8B-MLX-6bit` ships `ALTIC-MODEL-TERMS.md`. It permits use "only through official FluidVoice applications developed and distributed by ALTIC". Without written permission it forbids anyone to "host" it, or integrate it into "any third-party application, product, service, SDK, model, or hosted API". The Qwen-derived parts stay Apache 2.0. Source: https://huggingface.co/altic-dev/Fluid-1-Pico-0.8B-MLX-6bit/blob/main/ALTIC-MODEL-TERMS.md
- The same terms are on `Fluid-1-Quad-4B` (https://huggingface.co/altic-dev/Fluid-1-Quad-4B-MLX-6bit). `FluidIntelligence` (a Gemma derivative) is "personal, non-commercial use" only and forbids hosting (https://huggingface.co/altic-dev/FluidIntelligence).
- Pico's model card says it ships with a "DFlash drafter attached" and that "Output is byte-identical to plain greedy decoding". A drafter is a small helper model that guesses several tokens ahead for the main model to check. Pico "Requires FluidIntelligence with causal DFlash block attention (September 2026 or later)". Its weights file is 648,222,782 bytes (`fluid-model-release.json`). Source: https://huggingface.co/altic-dev/Fluid-1-Pico-0.8B-MLX-6bit
- `Qwen3.5-0.8B` is a hybrid design: 18 of its 24 layers use linear attention and every fourth layer uses full attention (Pico's `config.json`). The runtime must support that design. I did not check whether llama.cpp's speculative decoding works with it.

## Assumptions used in every calculation

- Requests: 50 per user per day, 30-day month. That is 1,500 a month for 1 user and 15,000 for 10.
- Tokens per request: 1,000 in and 40 out, the top of the ticket's range.
- An always-on month is 730 hours.
- Latency budget: 250 ms = network round trip + reading the prompt (prefill) + generating 40 tokens + queueing.

### How the speed estimates work

For one request at a time, generating each token means reading every model weight from memory once, so speed is limited by memory bandwidth. I calibrated each chip's real bandwidth from measured llama.cpp results for Llama 2 7B Q4_0 (a 3.83 GB file, 3.56 GiB as llama-bench reports it; that size is from memory and was not re-checked):

- usable bandwidth = 3.83 GB x measured tokens per second
- 0.8B model, time for 40 tokens = 40 x 0.648 GB / usable bandwidth
- 8B model, time for 40 tokens = 40 / (7B tokens per second / 1.2). The 1.2 factor is 8.0B / 6.7B parameters.
- Prefill time for 1,000 tokens scales the same way from the measured 512-token prefill speed. For the 0.8B model I scaled by compute, 2 x 6.74B / (2 x 0.8B) = 8.4x faster than 7B.

The 0.8B numbers are a best case. Very small models usually lose time to fixed per-step overhead that this method ignores. I found no published single-request benchmark for a model under 1B on these GPUs, so measure before buying anything.

Cross-check: this method predicts 478 ms for 40 tokens on an 8-core M1. Alec measured a 608 ms median end to end, so the method lands in the right range.

## Measured speeds the options depend on

Source for NVIDIA cards: llama.cpp "Performance of llama.cpp on Nvidia CUDA", Llama 2 7B Q4_0, flash attention on, https://github.com/ggml-org/llama.cpp/discussions/15013. Source for Macs: "Performance of llama.cpp on Apple Silicon M-series", https://github.com/ggml-org/llama.cpp/discussions/4167. The M1-M4 rows use build `8e672ef` from Nov 2023, so today's runtimes, MLX included, are likely somewhat faster. The M5 row uses build `c1d0e7a`.

| Hardware | 7B prefill tok/s | 7B generate tok/s | 8B: 40 tokens | 8B: 1,000-token prefill | 0.8B: 40 tokens (best case) | 0.8B: 1,000-token prefill |
|---|---|---|---|---|---|---|
| T4 | 1,310 | 46.4 | 1,035 ms | 916 ms | 146 ms | 91 ms |
| L4 (no measurement; 300 GB/s from NVIDIA, A10G's efficiency assumed) | - | - | - | - | about 121 ms | - |
| A10G | 2,354 (FA off) | 111.5 | 430 ms | 510 ms | 61 ms | 50 ms |
| RTX PRO 4000 Blackwell | 5,674 | 136.4 | 352 ms | 211 ms | 50 ms | 21 ms |
| RTX 3090 | 5,560 | 161.9 | 296 ms | 216 ms | 42 ms | 21 ms |
| RTX 4090 | 14,771 | 189.0 | 254 ms | 81 ms | 36 ms | 8 ms |
| A100 80GB | 5,286 | 200.9 | 239 ms | 227 ms | 34 ms | 22 ms |
| H100 80GB | 11,263 | 280.7 | 171 ms | 107 ms | 24 ms | 11 ms |
| M1 (8-core GPU) | 118 | 14.2 | 3,392 ms | 10,173 ms | 478 ms | 1,006 ms |
| M1 Pro (16) | 266 | 36.4 | 1,318 ms | 4,507 ms | 186 ms | 446 ms |
| M1 Max (32) | 530 | 61.2 | 784 ms | 2,264 ms | 111 ms | 224 ms |
| M2 (10) | 180 | 21.9 | 2,191 ms | 6,683 ms | 309 ms | 661 ms |
| M2 Pro (19) | 341 | 38.9 | 1,235 ms | 3,517 ms | 174 ms | 348 ms |
| M3 (10) | 187 | 21.3 | 2,249 ms | 6,426 ms | 317 ms | 636 ms |
| M4 (10) | 221 | 24.1 | 1,991 ms | 5,423 ms | 281 ms | 536 ms |
| M4 Pro (20) | 440 | 50.7 | 946 ms | 2,729 ms | 133 ms | 270 ms |
| M4 Max (40) | 886 | 83.1 | 578 ms | 1,355 ms | 81 ms | 134 ms |
| M5 (10) | 723 | 31.9 | 1,506 ms | 1,660 ms | 212 ms | 164 ms |

The last four columns are estimates made with the method above. Takeaways:

- An 8B model misses 250 ms on every card listed without speculative decoding. On an H100 it needs 171 ms to generate plus 107 ms to prefill, which is 278 ms before any network time. That fits with Wispr pairing Llama 3.1 8B with speculative decoding (from the ticket context; not re-checked).
- A 0.8B model fits easily on any 24 GB-class data-centre or gaming card. A T4 is borderline (146 + 91 = 237 ms before network).
- On Macs, prefill of a long prompt hurts as much as generation. Caching the fixed instruction text, so each request only prefills the new transcript and context, matters as much as decode speed. The mlx-lm README documents prompt caching (`mlx_lm.cache_prompt`, `--prompt-cache-file`): https://github.com/ml-explore/mlx-lm

Memory bandwidth figures from vendor pages: L4 300 GB/s (https://www.nvidia.com/en-us/data-center/l4/), A10 600 GB/s (https://www.nvidia.com/en-us/data-center/products/a10-gpu/), L40S 864 GB/s (https://www.nvidia.com/en-us/data-center/l40s/), H100 SXM 3.35 TB/s (https://www.nvidia.com/en-us/data-center/h100/). RTX PRO 4000 Blackwell SFF 432 GB/s comes from the PNY-hosted NVIDIA datasheet via search; I did not open the PDF.

## Network round trips from London

Data-centre to data-centre ping, WonderNetwork, checked 2026-10-22 (https://wondernetwork.com/pings/London):

| To | ms |
|---|---|
| Paris | 7.3 |
| Amsterdam | 8.2 |
| Frankfurt | 17.2 |
| Helsinki | 36.4 |
| New York | 70.1 |
| Washington (nearest to Virginia, where many US clouds sit) | 75.4 |
| Chicago | 91.6 |
| Dallas | 100.2 |
| San Francisco | 134.3 |

- Home broadband adds its own delay at each end. I could not get a primary figure: Ofcom's report PDFs returned 403. From this Mac, at the time of writing, `ping` to 1.1.1.1 averaged 108 ms and to 8.8.8.8 100 ms. That is far above normal UK fibre, so this Mac was probably on a VPN or a remote network. Re-measure from home.
- Reuse one open HTTPS connection between requests. A fresh TCP + TLS handshake adds one or two more round trips on top of these figures.
- Modal sends all inputs through Virginia (`us-east`) by default, even when the container runs elsewhere. A `routing_region=` setting changes that, but it can only be set when a function is first deployed. Source: https://modal.com/docs/guide/region-selection

## Option 1: serverless GPU with scale-to-zero

Prices:

| Provider | Small GPU price | Idle time before scaling down | Cold start stated by vendor | Source |
|---|---|---|---|---|
| Modal | L4 $0.000222/s, T4 $0.000164/s, A10 $0.000306/s, H100 $0.001097/s; CPU $0.0000131/core/s; memory $0.00000222/GiB/s; $30/month free credit; picking a region costs 1.15x (broad, such as `eu`) or 1.75x (narrow, such as `uk`) | default 60 s, settable from 2 s to 20 min | "Containers boot in about one second", plus model loading. GPU memory snapshots are an "alpha feature" with no timing given. | https://modal.com/pricing, https://modal.com/docs/guide/cold-start, https://modal.com/docs/guide/memory-snapshot |
| RunPod Serverless | L4 / A5000 / 3090 class $0.69/h; A4000 / RTX 4000 class $0.58/h; H100 $4.79/h | default 5 s | "sub-200ms FlashBoot cold starts" (marketing page). FlashBoot keeps a stopped worker's state for a faster restart. The docs give no figure. | https://www.runpod.io/pricing, https://www.runpod.io/serverless-gpu, https://docs.runpod.io/serverless/endpoints/endpoint-configurations |
| Baseten | L4 $0.01414/min ($0.85/h), T4 $0.01052/min | not stated on the pricing page | not stated | https://www.baseten.co/pricing/ |
| Hugging Face Inference Endpoints | AWS L4 $0.80/h, T4 $0.50/h, billed by the minute | 15 minutes idle; returns `502 Bad Gateway` while starting, with no queue | "varies depending on your model's size" | https://huggingface.co/docs/inference-endpoints/en/pricing, https://huggingface.co/docs/inference-endpoints/en/autoscaling |
| Replicate | T4 $0.81/h, L40S $3.51/h | private models are billed for "all the time instances of the model are online", setup and idle included | fast-booting fine-tunes are billed only while active, but only for models labelled that way | https://replicate.com/pricing |
| Fly.io GPUs | - | - | The GPU docs URL now redirects to a post saying Fly is "scaling back our GPU ambitions". Not a candidate. | https://fly.io/blog/wrong-about-gpu/ |
| Cloudflare Workers AI | per token; see option 4 | - | - | - |

A third-party comparison (PremAI, March 2026) measured RunPod cold starts at 10-15 s, against RunPod's sub-200 ms claim. Its conditions are unknown, so treat the real figure as unknown until measured.

Cold starts decide this option.

- Waking the GPU only when the cleanup request arrives misses the target. Even a 1 s container boot is four times the whole 250 ms budget, before loading 648 MB of weights and starting the runtime.
- The app knows a cleanup is coming the moment recording starts. If it sends a wake-up request then, the container boots while the user is still speaking. The cleanup request then finds a warm container whenever the boot takes less time than the dictation. Short dictations ("yes, sounds good") will still sometimes hit a cold start. I found no vendor documentation of this approach; it uses only the ordinary scale-to-zero settings above.

Cost when the container starts at the beginning of recording (assumptions: 10 s average dictation, 0.3 s of inference, then the shortest idle window; every dictation billed on its own with no overlap, so this is a worst case):

- Modal L4 plus 1 CPU core and 8 GiB memory = $0.000222 + $0.0000131 + 8 x $0.00000222 = $0.000253/s.
  - Per dictation: 10 + 0.3 + 2 s = 12.3 s, x $0.000253 = $0.0031.
  - 1 user: 1,500 x $0.0031 = $4.67/month, inside the $30 credit, so $0.
  - 10 users: $46.65/month, or $16.65 after the credit.
  - With the `eu` region (1.15x): $5.37 and $53.65. With `uk` (1.75x): $8.16 and $81.64.
- RunPod Serverless L4 class, $0.69/h = $0.000192/s.
  - Per dictation: 10 + 0.3 + 5 s = 15.3 s, x $0.000192 = $0.0029.
  - 1 user: $4.40/month. 10 users: $43.99/month.
  - Restricting to EU regions "decreases the available GPU pool" (endpoint configuration docs).

Cost when kept warm during waking hours (16 h a day, the same at 1 or 10 users):

- Modal L4: $0.000253 x 57,600 s x 30 = $436.94 ($502.48 with `eu`).
- RunPod L4 class: $0.69 x 16 x 30 = $331.20.

Latency if the container is warm: a 0.8B model on an L4 (about 121 ms to generate, plus roughly 45 ms to prefill 1,000 tokens if the L4 sits between the T4 and A10G) plus a European round trip of 7-36 ms comes to about 175-200 ms. That passes. A US-routed Modal function adds 75 ms or more.

Setup effort: moderate. Package a container with the runtime and weights, add the wake-up call to the app, add authentication, add a fallback to local cleanup when the GPU is cold or down. Upkeep is low: no machine to patch.

Privacy: the provider's infrastructure carries the text. Modal keeps function inputs and outputs "Up to 7 days, then deleted", encrypts data at rest, and is SOC 2 Type II with a GDPR data processing addendum (https://modal.com/docs/guide/security). RunPod `/runsync` keeps results for 1 minute (5 max) and `/run` for 30 minutes (https://docs.runpod.io/serverless/endpoints/send-requests). RunPod's "load balancing endpoints" skip its job queue and send HTTP straight to the worker, listed as "Lower (single-hop)" latency (https://docs.runpod.io/serverless/load-balancing/overview). I did not find what RunPod retains for those.

Custom fine-tune: yes. Alec ships his own container and weights.

## Option 2: always-on rented GPU

One card handles 10 users with room to spare: 500 requests a day x about 0.3 s = 150 s of work a day. Cost is the same at 1 or 10 users.

| Offer | Location | Price | Per month | Fits a 0.8B model in 250 ms? | Source |
|---|---|---|---|---|---|
| RunPod Pod, RTX A5000, Community Cloud | not guaranteed | $0.16/h | $116.80 | likely; no measured A5000 row | https://www.runpod.io/pricing |
| RunPod Pod, RTX 3090, Community Cloud | not guaranteed | $0.22/h | $160.60 | yes (about 42 + 21 ms) | same |
| RunPod Pod, RTX A5000, Secure Cloud | not guaranteed | $0.27/h | $197.10 | likely | same |
| Hetzner GEX45, RTX PRO 4000 Blackwell SFF 24 GB | Helsinki, 36 ms | €214/month + €209 setup (first year €2,777) | €214 | likely; the SFF card has 432 GB/s against the full-size card's measured 136 tok/s | https://www.hetzner.com/dedicated-rootserver/matrix-gpu/ |
| RunPod Pod, L4, Secure Cloud | not guaranteed | $0.59/h | $430.70 | yes, about 175-200 ms in total | RunPod pricing |
| Scaleway L4-1-24G | Paris (PAR-1), 7 ms | €0.79/h | about €574.87 | yes | https://www.scaleway.com/en/pricing/gpu/ |
| Hugging Face Endpoint, AWS L4 | region not stated | $0.80/h | $584.00 | yes | HF pricing |
| Modal L4 kept on 24/7 (GPU + 1 core + 8 GiB) | any, `eu` +15% | $0.91/h | $664.52 | yes | Modal pricing |
| Lambda A10 | US | $1.29/h | $941.70 | yes, but US round trip | https://lambda.ai/pricing |

For an 8B model inside 250 ms you need H100 class:

| Offer | Per month |
|---|---|
| Modal H100, 24/7 | $2,882.92 |
| RunPod Serverless H100 kept on | $3,496.70 |
| Together dedicated H100, $5.49/h (https://www.together.ai/pricing) | $4,007.70 |
| Fireworks on-demand H100, $8.00/h (https://fireworks.ai/pricing) | $5,840.00 |

Cold start: none while the machine runs.

Setup and upkeep: highest of all options. One developer has to patch the OS, drivers and runtime, handle TLS and authentication, and set up monitoring. A host failure means an outage unless the app falls back to local cleanup.

Privacy: on Hetzner or Scaleway the text stays on a machine Alec controls, but the host could in principle reach it. RunPod's Community Cloud machines belong to third-party hosts. RunPod's security page says Secure Cloud uses "vetted infrastructure partners" and that hosts are prohibited from inspecting Pod or worker data (https://docs.runpod.io/references/security-and-compliance).

Custom fine-tune: yes.

Break-even: the prior ticket put per-token hosting at $20-72 a month per 1,000 users, which is $0.020-0.072 per user. A $197.10 card therefore pays off only at $197.10 / $0.072 = 2,738 users up to $197.10 / $0.020 = 9,855 users. For the $160.60 Community 3090 the range is 2,231 to 8,030 users.

## Option 3: Alec's second Mac as a home server

Speed: everything depends on the chip, which I could not establish. Alec's CLAUDE.md names a second Mac, `alechamilton@SUMUP-M9Y197RFVG.local`. When I tried to read its chip over SSH it returned "No route to host", probably because it was asleep. The "SUMUP" hostname suggests a work-managed machine. If so, check the employer's rules before serving friends' traffic from it, and expect a laptop to sleep and move between networks.

From the table above, for a 0.8B model with no speculative decoding and a 300-token new prompt:

| Chip | Generate 40 tokens | Prefill 300 tokens | Verdict |
|---|---|---|---|
| M1, M2, M3, M4 base | 281-478 ms | 161-302 ms | misses 250 ms before any network time |
| M5 base | 212 ms | 49 ms | borderline |
| M1 Pro, M2 Pro, M4 Pro | 133-186 ms | 81-134 ms | about 215-320 ms; needs speculative decoding |
| M1 Max, M4 Max | 81-111 ms | 40-67 ms | passes |

An 8B model misses the target on every Mac listed: 578 ms or more just to generate 40 tokens.

Reaching it from anywhere with Tailscale (a WireGuard-based private network between your own devices):

- Connections start through Tailscale's relay servers (called DERP) and upgrade to direct device-to-device links when possible. "In most environments, Tailscale successfully establishes direct connections", but a direct link is impossible when both ends sit behind a "hard NAT" (a router type that blocks the hole-punching Tailscale relies on). Relayed connections "are generally slower". Source: https://tailscale.com/kb/1257/connection-types
- The free Personal plan allows "Up to 6 users" and is "only suitable for non-commercial use" (https://tailscale.com/pricing). Device sharing lets a friend in another tailnet reach only the shared Mac, which "cannot start connections" back. It is "available for all plans", but the recipient must be an Owner, Admin or IT admin of their own tailnet (https://tailscale.com/kb/1084/sharing). So each friend installs Tailscale and runs their own tailnet.
- The alternative, Tailscale Funnel, publishes the Mac on the public internet through Tailscale relay servers. Those relays "do not decrypt the traffic". It only listens on ports 443, 8443 and 10000, and has "non-configurable bandwidth limits" with no figures given (https://tailscale.com/kb/1223/funnel). Funnel needs the app to carry its own access key.
- Added latency: the home-to-home round trip was not measured. Within the UK on a direct link it is roughly the London data-centre figures above plus both homes' broadband delay. Measure it with `tailscale ping <mac>` from a friend's network.

Cost: Mac mini idle power is 4 W (M4) to 7 W (M2), per Apple's measurements (https://support.apple.com/en-us/103253). 7 W x 730 h = 5.11 kWh. At the Ofgem cap's average 26.32p per kWh for 1 Oct - 31 Dec 2026 (https://www.ofgem.gov.uk/your-energy-supply/your-energy-bill/energy-price-cap-unit-rates-and-standing-charges) that is £1.34 a month. Inference adds almost nothing. Tailscale is free at this size. The hardware is already owned.

Cold start: none if the model stays loaded and the Mac never sleeps. Turn off automatic sleep in Energy settings and survive macOS update restarts with a login item that relaunches the server.

Setup: low to moderate. Run `mlx_lm.server` or a llama.cpp server, add Tailscale, give each friend a key. Upkeep: home power and broadband cuts become outages, and the Mac owner's own GPU use competes with requests. The app needs a fallback to local cleanup.

Privacy: best of the network options. Tailscale traffic is end-to-end encrypted between devices, so only Alec's Mac sees the text. Alec, as host, could read friends' dictations.

Custom fine-tune: yes.

## Option 4: per-token services that serve your own fine-tune

| Service | What it will serve | Smallest base | Price | Cost at 1 / 10 users | Privacy terms read | Source |
|---|---|---|---|---|---|---|
| Cloudflare Workers AI | LoRA only, on 4 older models: `gemma-2b-it-lora`, `gemma-7b-it-lora`, `llama-2-7b-chat-hf-lora`, `mistral-7b-instruct-v0.2-lora`. Rank 8 or below (32 for larger ranks), file under 300 MB, base must not be quantised, up to 100 adapters. Uploads are adapter files only. | Gemma 2B | LoRA inference "free" during open beta. Plain Llama 3.2 1B costs $0.027 / $0.201 per million tokens in / out; 10,000 free "Neurons" (Cloudflare's billing unit) a day | Llama 3.2 1B: $0.05 / $0.53 | not read | https://developers.cloudflare.com/workers-ai/features/fine-tunes/loras/, https://developers.cloudflare.com/workers-ai/models/?capabilities=LoRA, https://developers.cloudflare.com/workers-ai/platform/pricing/ |
| CoreWeave (W&B Inference) | LoRA, rank 16 or below, on 5 bases incl. `meta-llama/Llama-3.1-8B-Instruct`. Billed "at the same rates as standard model inference" plus storage. Weights stored in `coreweave-us`. | 8B | Llama 3.1 8B $0.22 / $0.22 per million (W&B model page, via search) | $0.34 / $3.43 | retention not stated on the LoRA page | https://docs.coreweave.com/inference/lora, https://wandb.ai/site/inference/meta-llama-31-8b/ |
| Fireworks | "Serverless deployment is not supported for LoRA models"; on-demand dedicated only. (The pricing page still says "Serve fine-tuned models for the same price as base models", which conflicts.) | - | H100 $8.00/h dedicated | $5,840/month | "Zero Data Retention by default" for open models; logs metadata such as token counts | https://docs.fireworks.ai/fine-tuning/deploying-loras, https://docs.fireworks.ai/guides/security_compliance/data_handling |
| Together | "Serverless LoRA inference ... has been discontinued"; dedicated endpoints only | - | H100 $5.49/h | $4,008/month | not read | https://docs.together.ai/docs/lora-inference |
| Groq | LoRA inference for enterprise-tier customers only, via sales. This comes from a search summary of Groq's docs; the docs themselves returned 403. | - | not published | - | not read (403) | https://console.groq.com/docs/lora |
| Nebius Token Factory | says "Deploy serverless LoRA adapter models ... with per-token billing" | not established (docs page 404) | not established | - | not read | https://docs.tokenfactory.nebius.com/fine-tuning/overview.md |
| OpenAI fine-tuning | a fine-tuned `gpt-4.1-nano`, not your own weights. The page says "OpenAI is winding down the fine-tuning platform". | - | $0.20 / $0.80 per million | $0.35 / $3.48 | not read | https://developers.openai.com/api/docs/pricing |

Cost arithmetic: 10 users = 15,000 requests x 1,000 tokens in = 15M input tokens, plus 15,000 x 40 = 0.6M output tokens.

- CoreWeave Llama 3.1 8B: 15 x $0.22 + 0.6 x $0.22 = $3.43.
- Cloudflare Llama 3.2 1B: 15 x $0.027 + 0.6 x $0.201 = $0.53.

Latency: none of these pages publish time to first token or tokens per second for custom adapters. CoreWeave keeps LoRA weights in the US, so add 70-135 ms of round trip from London before any inference. Fireworks' multi-LoRA serving adds "often +10-30%" to time to first token. Its single-adapter merged mode "matches the base model".

Cold start: none stated for per-token serving. Fireworks and Together dedicated endpoints are always on.

Setup: lowest. Train a LoRA on a supported base, upload it, call an HTTPS API. The catch is that none of them take a 0.8B Qwen3.5 fine-tune. The cleanup model would have to be retrained on Llama 3.1 8B (CoreWeave) or an older Gemma/Mistral (Cloudflare).

## Option 5: make cleanup on the user's own Mac faster

- The M1 is close to its limit without speculative decoding. The estimate is 478 ms to generate 40 tokens (12 ms per token, from 648 MB / 54 GB/s). Alec measured 608 ms in total. To reach 250 ms the M1 must produce about 2.5 tokens per weight read.
- Speculative decoding produces several tokens per weight read and leaves the output unchanged:
  - Pico already ships a DFlash drafter with "byte-identical" output, if the runtime supports it. The DFlash paper (arXiv 2602.06036, submitted 5 Feb 2026, ICML 2026) reports "over 6x lossless acceleration across a range of models and tasks", measured on larger models than 0.8B (https://arxiv.org/abs/2602.06036v1). I could not tell whether Alec's 608 ms already used the drafter. Check that first.
  - Prompt lookup decoding guesses the next tokens by finding matching text in the prompt, with no extra model. It suits cleanup because the output mostly copies the transcript. Its author reports "2x-4x" on input-grounded tasks and an average "2.4x" on summarisation (Mistral 7B on an A100) (https://github.com/apoorvumang/prompt-lookup-decoding).
  - llama.cpp has the same idea as `--spec-type ngram-simple` / `ngram-mod`. Its docs name "the rewriting of source code by a LLM" as a fit (https://github.com/ggml-org/llama.cpp/blob/master/docs/speculative.md). vLLM offers `"method": "ngram"` with `prompt_lookup_min` / `prompt_lookup_max` (https://docs.vllm.ai/en/latest/features/speculative_decoding/).
  - mlx-lm supports draft-model speculative decoding (`--draft-model`, `--num-draft-tokens`, default 3) (https://github.com/ml-explore/mlx-lm/blob/main/mlx_lm/generate.py). I saw no prompt-lookup mode in mlx-lm.
- Prefill: 1,000 new tokens take about 1 s on an M1, so cache the fixed instructions with mlx-lm's prompt cache. Then only the transcript and the per-request context get prefilled.
- Faster friends' Macs need less help. An M1 Pro needs about 186 ms for 40 tokens and an M4 Pro about 133 ms. Base M1-M4 chips need speculative decoding.
- Apple Neural Engine: ALTIC publishes Core ML builds of Pico (`altic-dev/Fluid-1-Pico-0.8B-CoreML`) under the same no-third-party-use terms. I found no published speed figures for them.

## Summary table

| Option | 1 user / month | 10 users / month | Fits 250 ms with 0.8B? | Cold start | Effort | Who sees the text | Own fine-tune? |
|---|---|---|---|---|---|---|---|
| 1. Modal serverless, container started when recording begins, `eu` region | $5.37 (inside $30 credit) | $53.65 ($23.65 after credit) | yes when warm; cold start unmeasured | hidden when boot takes less time than the dictation | moderate | Modal, kept up to 7 days | yes |
| 1. RunPod serverless, same approach | $4.40 | $43.99 | yes when warm | vendor claims under 200 ms; third party measured 10-15 s | moderate | RunPod; results kept 1-30 min | yes |
| 2. Always-on, RunPod Community 3090 | $160.60 | $160.60 | yes | none | high | Alec + an unvetted host | yes |
| 2. Always-on, Hetzner GEX45 (Helsinki) | €214 (+€209 setup) | €214 | likely | none | high | Alec + Hetzner | yes |
| 3. Home Mac + Tailscale | about £1.34 power | about £1.34 | only on Pro/Max-class chips, or with speculative decoding | none if it never sleeps | low to moderate | only Alec | yes |
| 4. CoreWeave LoRA on Llama 3.1 8B | $0.34 | $3.43 | latency unpublished; US round trip 70-135 ms | none | lowest | CoreWeave; retention not stated | 8B LoRA only |
| 4. Cloudflare Workers AI | $0.05 (plain 1B) | $0.53 | not measured | not stated | lowest | Cloudflare | LoRA on old 2B-7B bases only |
| 5. Local on the user's Mac with speculative decoding | $0 | $0 | M1: needs about 2.5x; M1 Pro or newer Pro chips: likely | none | moderate (runtime work) | nobody | yes |

## What would change the recommendation

- Friends' Macs: if most friends have Pro, Max or M5 chips, local cleanup alone meets the target and no server is needed.
- Pico's licence: written permission from ALTIC would remove the retraining step. Without it, every option needs Alec's own fine-tune.
- A per-token host adding Qwen3.5-0.8B LoRA support would beat every owned option on cost and effort.
- Measured cold start: if Modal or RunPod boot plus model load runs longer than typical dictations, the serverless option falls back to waking-hours keep-warm ($331-503 a month). The home Mac or local then win.
- Scale: an always-on card only beats per-token pricing at about 2,200-9,900 users.
- If the 8B quality is needed: per-token hosting wins outright. Self-hosting 8B inside 250 ms costs $2,900 or more a month.

## Not established

- The second Mac's chip. It was unreachable over SSH.
- Measured cold starts on Modal and RunPod for a 0.8B model.
- Single-request speed of any model under 1B on NVIDIA GPUs. The 0.8B GPU figures are bandwidth-based best cases.
- Whether llama.cpp's n-gram speculative decoding works with Qwen3.5's hybrid linear-attention layers.
- Whether Alec's 608 ms M1 measurement already used Pico's DFlash drafter.
- UK home broadband latency, and the home-to-home Tailscale round trip.
- Groq's data and LoRA pages (403), Nebius' supported LoRA bases (404), and RunPod's and Hugging Face's region lists.
- Retention terms for CoreWeave, Together and Cloudflare. A separate privacy ticket may cover them.
