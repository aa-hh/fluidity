# Can the FluidInference Core ML builds of Parakeet TDT v2 and v3 be retrained?

Type: research
Status: claimed
Blocked by: none

## Question

For these two specific builds:

- https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v2-coreml
- https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml

Can they be fine-tuned directly, or must we fine-tune the original NVIDIA weights and reconvert? If reconverting, can we reproduce exactly the conversion FluidInference used (möbius settings, quantization, model split), so the result drops into FluidAudio unchanged? What do their licences allow for commercial use and redistribution of retrained versions?
