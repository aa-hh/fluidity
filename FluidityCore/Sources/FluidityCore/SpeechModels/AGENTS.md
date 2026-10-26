# SpeechModels

## Purpose

The catalogue of on-device speech models, and downloading and deleting the
optional ones. It never chooses the model the user dictates with; only the
user does, through `Settings`.

## Rules

- **A model id's raw value is saved in every dictation record.** Renaming one
  breaks comparing new records with old ones; the TDT v2 id must stay the
  string records already hold.
- **A figure that was not measured is nil, never a number.** The settings pane
  shows "Not measured" for it.
- **FluidAudio reports download fractions, not bytes.** Bytes shown are the
  fraction times the catalogue size, so the catalogue size must stay close to
  the real download.
- **A cancelled or failed download leaves files behind.** FluidAudio keeps its
  cache on cancellation, so `ModelDownloads` removes the model's folder itself.
- **Apple's model is part of macOS:** it is never downloaded or deleted here.
- **Tests never touch real files or the network.** `ModelDownloads` reaches
  them only through `ModelFetching`; the real fetcher is untested.

## Map

- `SpeechModelID`, `SpeechModel` → the model ids and the catalogue.
- `ModelDownloads` → each model's install state, download, cancel, delete.
- `ModelFetching` → what `ModelDownloads` needs from files and the network.
- `FluidAudioModelFetcher` → `ModelFetching` over FluidAudio's model folders.
