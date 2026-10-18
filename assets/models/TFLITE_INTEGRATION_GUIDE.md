# NiyoSense TFLite & Audio DSP Integration Reference (v1.4.5)

**Implementation Status:** Fully implemented in Flutter/Dart via `lib/services/model_service.dart` and `lib/services/spectrogram_service.dart`.  
**Model Format:** TensorFlow Lite (`.tflite`) Float32  
**Target Architecture:** Dual-Model On-Device Edge Inference (100% Offline)

---

## 1. Dual-Model Architecture Overview

NiyoSense uses two independent **YOLOv8-cls** models exported to TensorFlow Lite format:

1. **Visual Husk Model (`assets/models/img_best_v2.tflite`)**:
   * Evaluates the outer visual husk coloration, fiber texture, and shape.
   * **Input Tensor Shape**: `[1, 320, 320, 3]` NHWC RGB Float32.
   * **Normalization**: Divided by `255.0` (range `0.0` to `1.0`).
   * **Output**: Float array of size `[1, 2]` corresponding to `[0: buko, 1: malauhog]`.

2. **Acoustic Spectrogram Model (`assets/models/spec_best_v2.tflite`)**:
   * Evaluates the internal resonance of the coconut cavity from a 4-second knock recording.
   * **Input Tensor Shape**: `[1, 320, 320, 3]` NHWC RGB Float32.
   * **Colormap**: 256-color Matplotlib `magma` gradient.
   * **Output**: Float array of size `[1, 2]` corresponding to `[0: buko, 1: malauhog]`.

---

## 2. Audio Capture & On-Device Spectrogram DSP Pipeline

Audio preprocessing is executed entirely in native Dart (`SpectrogramService.dart`) without server-side dependencies:

* **Hardware Recording Source:** `AndroidAudioSource.unprocessed` (low-latency PCM, disabled hardware noise cancellation/AGC to preserve coconut cavity resonance frequencies).
* **Sample Rate:** `22,050 Hz`, Mono, 16-bit PCM WAV.
* **Duration:** Exactly `4.0 seconds` (`88,200 samples`).
* **High-Pass Filter:** First-order IIR filter with `300 Hz` cutoff to strip low-frequency hand handling noise.
* **Peak-Window Auto-Centering:** Scans for the highest acoustic energy burst across a `1.5-second` active tapping window.
* **Short-Time Fourier Transform (STFT):**
  * `n_fft = 2048`
  * `hop_length = 512`
  * Window: Periodic Hann window
* **Mel Filterbank:** `128` Slaney-normalized triangular Mel bands covering `0 Hz` to `11,025 Hz`.
* **Log-Power Normalization:** Dynamic range scaled from `-80 dB` to `0 dB`.
* **Colormap Conversion:** 256-color Matplotlib `magma` lookup table resized to `320×320` Float32 image tensor.

---

## 3. 3-Gate Out-of-Distribution (OOD) Pre/Post-Inference Validation

To ensure agricultural reliability and reject foreign objects (e.g., green bottles, synthetic toys, grass):

1. **Gate 1 — Optical Pixel & Texture Gate (`64×64` RGB)**:
   * **Luminance:** Mean $\mu \in [28, 242]$, Standard Deviation $\sigma \ge 8.0$.
   * **Center ROI Coconut Color Ratio:** Center 60% region must contain $\ge 40\%$ pixels in natural green/olive/brown coconut husk HSV ranges.
   * **Edge Roughness (Sobel Gradient):** Metric $\le 30.0$ to reject high-frequency clutter like weeds, bushes, and grass.
2. **Gate 2 — Spectrogram Tap-Stripe Counter (`64×64` Grid)**:
   * Analyzes the upper 70% frequency rows for distinct vertical acoustic impulse stripes (`colEnergy[x] > median + 35` and `> 85`).
   * Requires strictly between `2` and `5` valid acoustic taps separated by $\ge 3$ columns.
3. **Gate 3 — Softmax Temperature Scaling & Disagreement Resolution**:
   * Applies temperature scaling ($T = 1.6$).
   * Clamps maximum displayed confidence at `96.5%`.
   * Requires overall confidence $\ge 65.0\%$.
   * When models disagree, favors the acoustic model if acoustic confidence $\ge 75.0\%$.

---

## 4. Acoustic-Dominant 70/30 Decision Fusion Rule

The final maturity classification is calculated as:

$$P_{\text{final}}(c) = (0.70 \times P_{\text{audio}}(c)) + (0.30 \times P_{\text{visual}}(c))$$

$$\text{Final Class} = \begin{cases} \text{Buko (Mature)}, & \text{if } P_{\text{final}}(\text{buko}) > P_{\text{final}}(\text{malauhog}) \\ \text{Malauhog (Premature)}, & \text{otherwise} \end{cases}$$

**Domain Rationale:** External green husks of *Buko* and *Malauhog* coconuts are visually indistinguishable in field piles, whereas internal meat thickness (firm endosperm vs. mucus-like layer) creates distinct acoustic resonance frequencies under tapping.

---

## 5. Dart Integration Code (`ModelService.dart`)

```dart
// Load TFLite models
final imgInterpreter = await Interpreter.fromAsset('assets/models/img_best_v2.tflite');
final specInterpreter = await Interpreter.fromAsset('assets/models/spec_best_v2.tflite');

// Run inference on [1, 320, 320, 3] Float32 tensors
var imgOutput = List.filled(1 * 2, 0.0).reshape([1, 2]);
var specOutput = List.filled(1 * 2, 0.0).reshape([1, 2]);

imgInterpreter.run(normalizedImgTensor, imgOutput);
specInterpreter.run(normalizedSpecTensor, specOutput);

// 70% Acoustic / 30% Visual Late-Fusion Decision
double pBuko = (0.70 * specOutput[0][0]) + (0.30 * imgOutput[0][0]);
double pMalauhog = (0.70 * specOutput[0][1]) + (0.30 * imgOutput[0][1]);

String finalClass = (pBuko > pMalauhog) ? "Buko" : "Malauhog";
```
