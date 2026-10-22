# Can Parakeet models be retrained on new data?

Type: research
Status: claimed
Blocked by: none

## Question

Can NVIDIA Parakeet speech models (TDT 0.6B v2 and v3, and their relatives) be fine-tuned on a few hours to a few hundred hours of new English dictation? What tooling does it take (NVIDIA NeMo or others), what data format, what hardware and run time, and what accuracy gains do published fine-tunes report? How does a retrained model get converted to Core ML (Apple's on-device model format) for the Neural Engine, for example through Fluid Inference's möbius converter?
