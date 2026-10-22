# Retrain the best candidate on Alec's dictations and measure the gain

Type: task
Status: open
Blocked by: 01, 02, 05, 06

## Question

Fine-tune the best candidate from ticket 05 on Alec's own dictation data, convert it back for FluidAudio, and measure on the sealed test set: how much does the word error rate drop compared with the untouched model, and compared with FluidAudio's vocabulary boosting (biasing toward a word list without retraining)? Does speed hold?
