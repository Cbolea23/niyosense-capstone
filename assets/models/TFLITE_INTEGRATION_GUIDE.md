# NiyoSense Backend & AI Agent Handoff Guide

## 1. Project Overview
**Target Agent Instruction:** You are assisting a backend/Android developer in integrating the NiyoSense machine learning pipeline. You must strictly adhere to the architecture and preprocessing rules defined in this document.

NiyoSense is a **dual-modality (late-fusion) machine learning system** designed to classify the maturity of a coconut into two classes:
1. `buko` (Index 0)
2. `malauhog` (Index 1)

Instead of a single monolithic model, this system relies on **two YOLOv8 classification models** exported to TensorFlow Lite (`.tflite`). 

## 2. The Models
You will be integrating two separate `.tflite` files:
1. `img_model.tflite` - Evaluates the visual appearance (photo) of the coconut.
2. `spec_model.tflite` - Evaluates the acoustic resonance (knock sound) of the coconut via a spectrogram.

## 3. Preprocessing Requirements (CRITICAL)

### A. Image Model Preprocessing
- **Input Tensor**: `[1, 224, 224, 3]` (Standard RGB image, resized to 224x224).
- **Normalization**: Standard YOLOv8 TFLite float32 models expect normalized pixel values (divide by 255.0 so range is `0.0` to `1.0`).

### B. Audio/Spectrogram Preprocessing
You **cannot** feed raw audio bytes to the TFLite model. You MUST convert the recorded audio clip into a visual Mel Spectrogram image first, matching the exact parameters used during training.
- **Sample Rate (SR)**: `22050 Hz`
- **Duration**: Pad or trim the audio to exactly `4.0 seconds`.
- **STFT Params**: `n_fft = 2048`, `hop_length = 512`.
- **Mel Bands (n_mels)**: `128`
- **Colormap**: `magma` (CRITICAL: The model learned visual features based on the magma color gradient. Do not use viridis or grayscale).
- **Output Image**: Render the spectrogram without axes, margins, or borders. Resize the resulting RGB image to `224x224` and pass it into `spec_model.tflite`.

## 4. Late Fusion Logic (The Math)
Each model will output a float array of shape `[1, 2]` containing the probabilities for `[buko, malauhog]`.

**Rule:** Do NOT simply pick the highest probability from one model. You must combine the outputs using a weighted average (Late Fusion).

```kotlin
// Example Kotlin Integration Logic

// W is the fusion weight favoring the image model. 
// A baseline is 0.6 (60% image, 40% audio), but expose this so it can be tweaked.
val W = 0.6f 

// 1. Run inferences
val imgProbs = runImgModel(cameraImage)       // Returns floatArrayOf(P_buko, P_malauhog)
val specProbs = runSpecModel(spectrogramImage) // Returns floatArrayOf(P_buko, P_malauhog)

// 2. Apply Late Fusion
val finalBukoProb = (W * imgProbs[0]) + ((1f - W) * specProbs[0])
val finalMalauhogProb = (W * imgProbs[1]) + ((1f - W) * specProbs[1])

// 3. Determine Final Class
val finalClass = if (finalBukoProb > finalMalauhogProb) "buko" else "malauhog"
```

## 5. Android/Kotlin Setup
To run these models, ensure the standard TensorFlow Lite libraries are in your app-level `build.gradle`:
```gradle
implementation 'org.tensorflow:tensorflow-lite:2.14.0'
implementation 'org.tensorflow:tensorflow-lite-support:0.4.4'
```
Place both `.tflite` files in your Android `src/main/assets` directory and load them using `Interpreter`.

