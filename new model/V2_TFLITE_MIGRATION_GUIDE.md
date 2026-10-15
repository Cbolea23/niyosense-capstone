# NiyoSense V2 Model Migration Guide for AI Coding Agent (Gemini)

> **Directive for AI Agent (Gemini):**  
> You are tasked with upgrading the NiyoSense mobile application from the legacy V1 models to the **V2 Dual-Modality (Late Fusion) TFLite models**.  
> The V2 models were trained with expanded augmentation and achieve **95.45% test accuracy**.  
> You must strictly follow this guide to replace the old `.tflite` assets, update model references, enforce out-of-domain rejection, and ensure zero regressions.

---

## 1. Summary of Changes (V1 vs. V2)

| Feature | Legacy V1 Model | **New V2 Model** |
|---|---|---|
| **Image Model File** | `img_model.tflite` (or `img_best_float32.tflite`) | **`img_best_v2_float32.tflite`** |
| **Spectrogram Model File** | `spec_model.tflite` (or `spec_best_float32.tflite`) | **`spec_best_v2_float32.tflite`** |
| **Class Output (Index 0)** | `buko` | **`buko`** |
| **Class Output (Index 1)** | `malauhog` | **`malauhog`** |
| **Optimal Fusion Weight ($W$)** | $0.60$ (heuristic) | **$0.50$ (empirically tuned on validation set)** |
| **Input Dimensions (Both)** | `[1, 224, 224, 3]` (RGB float32) | `[1, 224, 224, 3]` (RGB float32, normalized 0.0–1.0) |
| **Test Accuracy** | ~85% | **95.45%** |

---

## 2. Step-by-Step Asset Replacement

### Step 2.1: Delete Old Assets
Locate the application assets folder:
- **Native Android (Kotlin/Java):** `app/src/main/assets/`
- **Flutter (Dart):** `assets/models/` or path declared in `pubspec.yaml`

**Actions:**
1. Delete all old model files (e.g., `img_model.tflite`, `spec_model.tflite`, `best_float32.tflite`, or previous V1 `.tflite` files).
2. Clean build caches (`Build > Clean Project` in Android Studio, or `flutter clean`).

### Step 2.2: Place New V2 Files
Copy the downloaded V2 models into the assets folder:
- `img_best_v2_float32.tflite`
- `spec_best_v2_float32.tflite`

*(Note: If your team prefers standard names without version tags, you may rename them to `img_model_v2.tflite` and `spec_model_v2.tflite`. Ensure names match your code constants exactly).*

### Step 2.3: Update Asset Declarations (Flutter Only)
If using Flutter, verify `pubspec.yaml` contains the new file paths:
```yaml
flutter:
  assets:
    - assets/models/img_best_v2_float32.tflite
    - assets/models/spec_best_v2_float32.tflite
```

---

## 3. Code Updates & Model Loading

Update the constants or initialization paths in your ML service class (e.g., `TFLiteService.kt` or `tflite_service.dart`):

### Kotlin Example:
```kotlin
object ModelConfig {
    const val IMG_MODEL_PATH = "img_best_v2_float32.tflite"
    const val SPEC_MODEL_PATH = "spec_best_v2_float32.tflite"
    
    // Class indexing: 0 = buko, 1 = malauhog
    val LABELS = arrayOf("buko", "malauhog")
    
    // V2 empirically tuned late fusion weight (50% visual, 50% acoustic)
    const val FUSION_WEIGHT_IMAGE = 0.50f
    
    // Out-of-domain / Confidence threshold (prevents false positives on non-coconuts)
    const val CONFIDENCE_THRESHOLD = 0.70f 
}
```

### Dart / Flutter Example:
```dart
class ModelConfig {
  static const String imgModelPath = 'assets/models/img_best_v2_float32.tflite';
  static const String specModelPath = 'assets/models/spec_best_v2_float32.tflite';
  
  static const List<String> labels = ['buko', 'malauhog'];
  
  // V2 tuned weight
  static const double fusionWeight = 0.50;
  
  // Rejection threshold
  static const double minConfidenceThreshold = 0.70;
}
```

---

## 4. Preprocessing Requirements (DO NOT MODIFY)

Both models expect an identical input tensor shape of `[1, 224, 224, 3]`:

1. **Image Preprocessing:**
   - Input: Camera photo of coconut husk.
   - Resize: Bilinear resize to $224 \times 224$.
   - Color: Standard RGB channels.
   - Normalization: Divide pixel values by $255.0$ (range: `[0.0, 1.0]`).

2. **Spectrogram (Acoustic) Preprocessing:**
   - The microphone recording (knock impacts) must be preprocessed via FFT before inference.
   - **Sample Rate ($SR$):** $22,050\text{ Hz}$
   - **Target Duration:** Exactly $4.0\text{ seconds}$ (pad with zeros if shorter, never truncate impact).
   - **STFT Parameters:** $n\_fft = 2048$, $hop\_length = 512$.
   - **Mel Bands ($n\_mels$):** $128$
   - **Scale:** Decibel / log power (`power_to_db` with `ref=max`).
   - **Color Mapping:** `magma` colormap (RGB format).
   - **Dimensions:** $224 \times 224 \times 3$ without axes, ticks, or borders.

---

## 5. Late Fusion & Out-of-Domain Guardrails

### 5.1 The Fusion Formula
Both models output Softmax probabilities across `[P(buko), P(malauhog)]`.

$$\text{Final } P(\text{class}) = W \cdot P_{\text{image}}(\text{class}) + (1 - W) \cdot P_{\text{spec}}(\text{class})$$

With $W = 0.50$:
```kotlin
val finalBukoProb = (0.50f * imgProbs[0]) + (0.50f * specProbs[0])
val finalMalauhogProb = (0.50f * imgProbs[1]) + (0.50f * specProbs[1])
```

### 5.2 Out-of-Domain Detection (Screen / Non-Coconut Rejection)
In the previous deployment, the app classified non-coconut objects (e.g., laptop screens, tables) because the model was forced to choose between `buko` or `malauhog`.

**Mandatory Logic to Implement:**
```kotlin
val maxConfidence = maxOf(finalBukoProb, finalMalauhogProb)

if (maxConfidence < ModelConfig.CONFIDENCE_THRESHOLD) {
    // REJECT SCAN
    return ScanResult.Rejected(
        message = "Coconut not detected or audio unclear. Please frame the coconut clearly and tap firmly."
    )
}

val predictedClass = if (finalBukoProb > finalMalauhogProb) "buko" else "malauhog"
return ScanResult.Success(
    maturity = predictedClass,
    confidence = maxConfidence
)
```

---

## 6. Migration Verification Checklist for Gemini

Before finalizing your PR/commit, verify the following:
- [ ] Old `.tflite` files removed from `assets/`.
- [ ] Both V2 models loaded without `FileNotFoundException` or asset packaging errors.
- [ ] Tensor input shape verified as `[1, 224, 224, 3]` float32.
- [ ] Index mapping strictly maintained: `Index 0 = buko`, `Index 1 = malauhog`.
- [ ] Fusion weight updated to $W = 0.50$.
- [ ] Confidence threshold ($\ge 0.70$) properly rejects non-coconut test images.
- [ ] App compiles and runs inference offline without crashes.

