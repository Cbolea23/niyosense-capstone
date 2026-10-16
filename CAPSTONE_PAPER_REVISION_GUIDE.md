# NiyoSense Capstone Paper Revision & Alignment Guide (v1.4.0)
**Prepared for:** Seann Yves Saracho (Manuscript & Documentation Lead)  
**Authors:** Christian Louis Bolea, Wayne Yzon Nagares, Seann Yves Saracho  
**Adviser:** Engr. Roselyn A. Maaño | **Technical Mentor / Panelist:** Prof. Eleazar Salanda  
**System Version:** `v1.4.0` (Build 12 — Final Production Build)

---

## 📌 Purpose of This Document
This guide directly compares our **Original Capstone 1 Proposal Manuscript** against our **Final Implemented System (`v1.4.0`)** so you can update every chapter, table, diagram, and methodology section in the revised Capstone paper with 100% technical accuracy.

---

## 🔄 1. Executive Summary Matrix: Old Paper vs. New Revised Paper (`v1.4.0`)

| Manuscript Section / Topic | What Was Written in Old Paper (Capstone 1) | What Must Be Written in New Paper (`v1.4.0` Capstone 2) |
| :--- | :--- | :--- |
| **ML Model Architecture** | Mentioned **YOLOv11** + server-side **Python Librosa** | **Dual On-Device YOLOv8-cls (`img_best_v2.tflite` & `spec_best_v2.tflite`)** exported to TensorFlow Lite (`tflite_flutter`), running **100% offline on the smartphone** with a custom **Pure-Dart STFT & Slaney Mel-Spectrogram DSP Engine (`SpectrogramService.dart`)** that mathematically replicates Python `librosa` on-device. |
| **Input Tensor Format** | `[1, 3, 224, 224]` NCHW or unspecified | **`[1, 320, 320, 3]` NHWC RGB Float32** normalized to `[0.0, 1.0]` for both Visual and Acoustic Mel-Spectrogram models. |
| **Maturity Classes** | 3 classes (`Premature`, `Mature`, `Overmature`) + `50` samples each (`150` total) | **2 Target Young Coconut Classes** (`0: Buko` [Marketable / Mature Young Coconut with firm meat] vs. `1: Malauhog` [Premature / Mucus-like thin meat]) + **Deterministic Out-of-Distribution (`Unrecognized`) Rejection State** via a 3-Gate Pre-Inference Validation Pipeline. |
| **Multimodal Late-Fusion Formula** | Unspecified or `60% Visual / 40% Audio` (`0.60 V + 0.40 A`) | **70% Acoustic / 30% Visual Weighted Late-Fusion** ($P_{\text{fused}} = 0.70 \cdot P_{\text{audio}} + 0.30 \cdot P_{\text{visual}}$). **Justification:** External green husks of *Buko* and *Malauhog* are visually near-identical in the field, whereas internal endosperm meat thickness and water cavity resonance produce distinct acoustic knock signatures. |
| **Out-of-Distribution (OOD) / Non-Coconut Handling** | None (relied on raw CNN output) | **3-Gate Deterministic Pre-Inference & Post-Inference Validation Pipeline** (Gate 1: `64×64` HSV Husk Color + Luminance + Sobel Grass/Foliage Edge-Roughness Gate; Gate 2: `64×64` Spectrogram Vertical Tap-Stripe Counter requiring `2–5` knocks; Gate 3: Softmax Temperature Scaling $T=1.6$, `96.5%` confidence cap, and Acoustic-Dominant Cross-Model Verification). |
| **Audio Recording Format & Preprocessing** | Recorded in `.M4A` format indoors | Recorded in **uncompressed 16-bit PCM `.WAV` (`22,050 Hz`, mono, 4.0 seconds)** using `AndroidAudioSource.unprocessed` (hardware AGC/Noise-Suppression disabled), followed by a **300 Hz High-Pass Filter**, **1.5s Peak-Window Auto-Centering**, **Hann STFT (`n_fft=2048, hop=512`)**, **128 Slaney Mel bands**, **$-80\text{ dB}$ to $0\text{ dB}$ normalization**, and **Matplotlib `magma` colormap**. |
| **Post-Harvest Sampling Unit** | Individual coconut per scan (`1 scan = 1 nut`) | **Bungkos (Cluster) Representative Sampling (`bunch_count`)**: In real Quezon Province farm workflows, coconuts are harvested and graded by cluster (*bungkos*, typically 8–15 nuts per bunch). Scanning 1 representative nut profiles the entire *bungkos*, and the sorter inputs the exact **Bungkos Coconut Count (`bunch_count`)** so all dashboard volume KPIs, charts, and financial valuations track both **Total Coconuts** and **Sampled Bunches**. |
| **Commercial & Financial Features** | Only mentioned basic inventory & grading logs | **Batch Delivery Session & Farmer Payout Voucher System** (mobile) + **Estimated Valuation Engine & Commercial Settlement / Profit Reconciliation (Price Variance / Leakage Detection)** (web dashboard). |
| **Multi-Device & Multi-Operator Architecture** | Mentioned single user / Vercel + Neon serverless | **Dockerized Django + Gunicorn + WhiteNoise + Cloudflare Tunnel (`trycloudflare.com`)** with **30-Day Multi-Device JWT Authentication**, **SQLite WAL Mode + 5-Attempt Atomic Locking Retry** for simultaneous multi-phone synchronization, **Unique Hardware Device ID (`device_id`)**, and **Role-Based Field Operator Accounts**. |

---

## 📖 2. Chapter-by-Chapter Manuscript Revisions (Exact Replacements)

### 2.1 Abstract (Lines 162–164 of Old Paper)
**What to Change:**
- Replace `YOLOv11` with **YOLOv8-cls deployed via TensorFlow Lite (`tflite_flutter`)**.
- Mention the **70% Acoustic / 30% Visual Late-Fusion Architecture** and the **3-Gate Pre-Inference Out-of-Distribution (OOD) Validation Pipeline**.
- Mention **Bungkos (Cluster) Sampling** and **Commercial Batch Valuation & Settlement Reconciliation**.

**Ready-to-Paste Revised Abstract:**
> Small-scale coconut aggregators in the Philippines rely on subjective manual tapping and visual inspection for maturity grading, leading to inconsistent quality assessment, sorting disputes, and post-harvest financial losses. Existing digital solutions lack integrated, offline-capable mobile tools that combine both visual and acoustic data for accurate field sorting. This study develops **NiyoSense**, a web and mobile coconut maturity profiling and grading system that utilizes multimodal audio-visual machine learning to provide standardized, objective grading for small-scale aggregators. The system employs dual **YOLOv8-cls** convolutional neural networks exported to **TensorFlow Lite (`320×320` Float32)** for visual husk analysis and acoustic Mel-spectrogram classification, supported by a pure-Dart Short-Time Fourier Transform (STFT) signal processing pipeline that converts 4-second raw `.wav` knock recordings into 128-band Slaney Mel-spectrograms on-device. To reflect the physical reality that external green husks of *Buko* (mature marketable young coconut) and *Malauhog* (premature mucus-like coconut) are visually similar while internal meat thickness alters acoustic resonance, predictions are combined via an **acoustic-dominant 70/30 late-fusion architecture ($0.70 \cdot P_{\text{audio}} + 0.30 \cdot P_{\text{visual}}$)** protected by a **3-Gate Out-of-Distribution (OOD) Validation Pipeline** and Softmax temperature scaling ($T = 1.6$). Built with Flutter and local SQLite storage, the mobile application supports 100% offline field grading, **cluster (*bungkos*) volume accounting**, and farmer delivery batch payout vouchers, while a Dockerized Django web dashboard provides concurrent multi-device synchronization, real-time harvest analytics, and commercial settlement reconciliation. Evaluation against ISO/IEC 25010 standards validates the system's functional suitability, performance efficiency, usability, and reliability for rural post-harvest operations.
>
> **Index Terms:** *Acoustic signal processing, agricultural automation, audio-visual late fusion, bungkos cluster sampling, coconut maturity grading, Mel-spectrogram, mobile decision support system, TensorFlow Lite, YOLOv8-cls.*

---

### 2.2 Chapter 2: Introduction — Objectives & Scope (Lines 170–187 of Old Paper)
**Updates Needed in Section 2.3 (Specific Objectives):**
1. **Specific Objective 1 (Dataset):** Update from *"150 coconut samples (50 per category) in PNG and M4A"* to:
   - Gathering and preprocessing a multimodal dataset of young coconuts categorized into **Buko** (mature young coconut with firm, marketable meat) and **Malauhog** (premature young coconut with thin, mucus-like meat), capturing visual husk images and standardized 4.0-second uncompressed `.wav` acoustic tapping signals (3–4 taps per sample) converted into `320×320` Mel-spectrograms (`magma` colormap).
2. **Specific Objective 3 (Model Development):** Update from *"YOLOv11"* to:
   - Developing and training dual **YOLOv8-cls** deep learning classification models (`img_best_v2.tflite` and `spec_best_v2.tflite`) integrated with a **3-Gate Out-of-Distribution (OOD) Pre-Inference Validation Pipeline** and an **Acoustic-Dominant 70/30 Late-Fusion Engine**.
3. **Specific Objective 4 (Mobile & Web Development):** Add:
   - Developing the offline-first Flutter mobile app with **Bungkos (Cluster) coconut count input**, **Farmer Delivery Batch Session & Payout Voucher generation**, and **English/Tagalog localization**, paired with a Dockerized Django Web Dashboard featuring **concurrent multi-device bulk synchronization**, **Estimated Harvest Valuation**, and **Commercial Settlement Reconciliation**.

**Updates Needed in Section 2.5 (Scope and Limitation):**
- **Binary Target Focus (*Buko* vs. *Malauhog*):** Clarify that the deployed model focuses on the critical post-harvest commercial distinction between **Buko (Mature / Marketable Young Coconut)** and **Malauhog (Premature / Mucus-like Young Coconut)**, while providing manual/commercial tally fields for **Bungi (Reject/Damaged)** during batch settlement.
- **Bungkos (Cluster) Sampling Methodology:** State that following standard agricultural practice in Quezon Province, harvested coconuts are grouped by cluster (*bungkos*). Scanning one representative nut from a *bungkos* establishes the maturity grade for that cluster, with the operator recording the cluster's nut count (`bunch_count`, typically 8–15 pieces).
- **Environmental Guardrails:** Instead of passively suffering from background noise or non-coconut images, the system actively enforces **Gate 1 (Camera Pixel & Texture Gate)** and **Gate 2 (Spectrogram Tap-Stripe Gate)** to reject invalid captures (`Unrecognized`) and prompt the operator to re-scan.

---

### 2.3 Chapter 3: Theoretical & Conceptual Framework (Lines 189–287 of Old Paper)
1. **Section 3.1 (Concept Map) & Section 3.4 (Conceptual Framework - Fig. 3):**
   - Replace `YOLOv11` $\rightarrow$ **`YOLOv8-cls (TensorFlow Lite)`**.
   - Replace `Python Librosa (Backend)` $\rightarrow$ **`On-Device Dart STFT & Slaney Mel-Spectrogram Engine (SpectrogramService)`**.
   - Replace `Vercel` $\rightarrow$ **`Dockerized Django Server + Gunicorn + Cloudflare Tunnel`**.
   - Update **Definition of Terms (Section 3.5)** to include:
     - **Buko:** Marketable young coconut stage characterized by a firm, spoon-soft endosperm layer and resonant hollow acoustic tap signature.
     - **Malauhog:** Premature young coconut stage characterized by a very thin, translucent, mucus-like endosperm layer and a dull/dampened acoustic tap signature.
     - **Bungkos (Cluster Sampling):** A harvested bunch/cluster of coconuts from a single spadix (typically 8–15 nuts) that shares a uniform physiological maturity stage.
     - **Mel-Spectrogram:** A time-frequency visual representation of an acoustic signal mapped onto the perceptual Mel frequency scale and rendered using the `magma` color lookup table for CNN classification.
     - **Late Fusion (70/30 Acoustic-Visual Split):** A multimodal decision-level integration strategy that weights the acoustic classification probability at 70% and the visual husk probability at 30%.
     - **Out-of-Distribution (OOD) Validation Gate:** Deterministic pre-inference signal and image checks that reject non-coconut objects, extreme lighting, or invalid tap counts before neural network fusion.

---

### 2.4 Chapter 4: Operational Framework — Software & Data Tables (Lines 288–371 of Old Paper)
**Update Table 2 (Software Requirements):**
- **Machine Learning:** `Ultralytics YOLOv8-cls` & `TensorFlow Lite (tflite_flutter ^0.12.1)` — Used for training `320×320` visual and Mel-spectrogram classification models and executing 100% offline inference on Android smartphones.
- **Audio Signal Processing:** `Python Librosa` (for offline dataset preparation) & **Custom Pure-Dart DSP (`SpectrogramService.dart`)** — Implements 300 Hz high-pass filtering, 1.5s peak-window centering, Hann STFT (`n_fft=2048, hop=512`), and 128 Slaney Mel filterbanks directly on the mobile device.
- **Web/Backend Hosting & Deployment:** `Docker Compose + Gunicorn + WhiteNoise + Cloudflare Tunnel (cloudflared)` — Containerized production environment with persistent volume mounts (`/app/media` and `/app/static`) and HTTPS zero-trust tunneling for multi-network mobile synchronization.
- **Database:** `SQLite (sqflite)` on mobile for offline storage; `SQLite WAL (Write-Ahead Logging) / PostgreSQL` on backend with 30-second busy timeout and 5-attempt atomic transaction retry for concurrent multi-phone sync.

---

## 🔬 3. Chapter 5: Complete Technical Methodology & Mathematical Formulas (New Section Content for Paper)

Your 3rd member should include the following **5 core technical subsections and equations** in **Chapter 5 (Description of Methods or Approach / System Architecture)** to align with panel and adviser expectations:

### 3.1 On-Device Acoustic Signal Processing Pipeline (`SpectrogramService.dart`)
When the field operator taps a coconut 3–4 times during the 4.0-second recording window, the mobile application captures raw audio and transforms it into a `320×320` RGB Mel-spectrogram image entirely offline:
1. **Unprocessed Hardware Capture:** Recorded at `22,050 Hz` mono 16-bit PCM (`.wav`) using `AndroidAudioSource.unprocessed` (`autoGain: false`, `noiseSuppress: false`, `echoCancel: false`) so Android OS voice filters do not suppress percussive wood/knuckle knocks.
2. **First-Order High-Pass Filter ($f_c = 300\text{ Hz}$):** Removes low-frequency wind rumble, hand-handling thuds, and ambient hum:
   $$y[n] = \alpha \left(y[n-1] + x[n] - x[n-1]\right), \quad \alpha = \frac{RC}{RC + \Delta t}, \quad RC = \frac{1}{2\pi \cdot 300}$$
3. **Peak-Window Auto-Centering (1.5-Second Active Window):** Scans the filtered waveform using a `1.5s` sliding window (`step = 0.05s`) to locate the highest acoustic energy segment containing the 3–4 knocks and centers it before spectral conversion.
4. **Short-Time Fourier Transform (STFT) & Slaney Mel-Filterbank:** Applies a periodic Hann window ($N_{\text{fft}} = 2048$, $\text{hop} = 512$) and maps power spectra onto $M = 128$ triangular Slaney-normalized Mel bands ($0\text{ Hz}$ to $11,025\text{ Hz}$), converting power to decibels normalized to $[-80\text{ dB}, 0\text{ dB}]$ and rendering pixels via the 256-entry Matplotlib `magma` color lookup table at `320×320` resolution.

---

### 3.2 3-Gate Pre-Inference & Post-Inference Out-of-Distribution (OOD) Validation Pipeline
Because standard Softmax classification networks (`YOLOv8-cls`) trained on closed-set classes (*Buko* vs. *Malauhog*) can assign high probabilities to out-of-distribution inputs (e.g., grass, concrete, faces, or silent/noisy audio) without requiring a third "non-coconut" class that could degrade boundary precision, NiyoSense implements a deterministic **3-Gate Validation Pipeline** in [`ModelService.dart`](file:///d:/desktop/GITHUB/niyosense-capstone/lib/services/model_service.dart):

- **Gate 1: Camera Pixel & Texture Validation (`64×64` Downsampled RGB):**
  1. *Luminance & Exposure Check:* Rejects covered lenses or overexposed glare if mean luminance $\mu_Y \notin [28, 242]$ or standard deviation $\sigma_Y < 8.0$.
  2. *Center-ROI Husk Chromaticity Check:* Evaluates the central 60% bounding box (`x, y ∈ [12, 52]`) in HSV space. Requires at least **40%** of center pixels to match natural green/yellow-green/olive-brown coconut husk chromaticity ($H \in [32^\circ, 158^\circ], S \in [0.14, 0.92], V \in [0.15, 0.92]$).
  3. *Sobel Edge-Roughness Texture Check:* Computes horizontal and vertical luminance gradients ($g_x, g_y$). A smooth coconut shell yields low spatial gradient roughness ($\le 30.0$), whereas grass blades, leaves, or gravel exceed `30.0` and are rejected before inference.

- **Gate 2: Mel-Spectrogram Vertical Tap-Stripe Counter (`64×64` Grid):**
  - Rather than relying on raw microphone amplitude (which varies across phone hardware), Gate 2 inspects the generated Mel-spectrogram image across the **upper 70% frequency rows** (`y = 0..44`, ignoring the bottom 30% low-frequency microphone hum).
  - For each time column $x \in [0, 63]$, mean brightness `colEnergy[x]` is compared against the background median:
    $$\text{isTapColumn}(x) \iff \text{colEnergy}[x] > \text{median}(\text{colEnergy}) + 35 \quad \text{and} \quad \text{colEnergy}[x] > 85$$
  - Distinct vertical stripes separated by at least 3 time columns are counted (`stripeCount`). A scan is accepted **if and only if `2 <= stripeCount <= 5`** (matching the SOP of 3–4 taps). Silence (`0–1` stripes) or continuous speech/clapping (`> 5` stripes) is immediately rejected as `Unrecognized`.

- **Gate 3: Softmax Temperature Scaling ($T = 1.6$), Confidence Cap (`96.5%`), & Cross-Model Agreement:**
  - Raw YOLOv8-cls probabilities $p_i$ are softened via temperature scaling ($T = 1.6$) to prevent artificial `99.9%–100.0%` saturation:
    $$\hat{P}_i = \frac{p_i^{1/T}}{\sum_{j} p_j^{1/T}}, \quad T = 1.6$$
  - Displayed confidence is capped at **96.5%** ($\min(\text{conf}, 0.965)$).
  - Minimum fused confidence threshold is **65.0%**. If the Visual and Acoustic models predict opposite classes, the scan is rejected as `Unrecognized` **unless** the Acoustic model is highly decisive ($\max(P_{\text{audio}}) \ge 0.75$), in which case the 70/30 fusion proceeds.

---

### 3.3 Acoustic-Dominant 70/30 Multimodal Late-Fusion Formula
In field conditions, *Buko* and *Malauhog* harvested from green bunches exhibit nearly identical outer husk color and shape, whereas internal meat thickness and water cavity volume strongly modulate acoustic knock resonance. Therefore, the late-fusion classifier applies a **70% Acoustic / 30% Visual weighting**:
$$P_{\text{fused}}(c) = 0.70 \cdot \hat{P}_{\text{audio}}(c) + 0.30 \cdot \hat{P}_{\text{visual}}(c), \quad c \in \{\text{Buko}, \text{Malauhog}\}$$
$$\text{Predicted Stage} = \arg\max_{c} P_{\text{fused}}(c)$$

---

### 3.4 Bungkos (Cluster) Sampling & Volume Accounting Formula
In small-scale coconut aggregation, harvesters cut entire clusters (*bungkos*) from a tree spadix. Since nuts within a single *bungkos* develop simultaneously, scanning one representative coconut grades the entire cluster. On `ScanResultScreen`, the operator inputs the cluster's nut count $n_i$ (`bunch_count`, default `10`, quick-select chips `8, 10, 12, 15`). Total graded volume across $K$ scanned clusters is computed as:
$$\text{Total Graded Coconuts} = \sum_{i=1}^{K} n_i, \qquad \text{Total Sampled Bunches} = K$$
$$\text{Stage Volume}(s) = \sum_{i \in \Omega_s} n_i$$
where $\Omega_s$ is the set of scanned clusters classified under maturity stage $s$.

---

### 3.5 Commercial Valuation & Profit Reconciliation (Leakage) Formulas
1. **Estimated Batch Valuation ($V_{\text{est}}$):**
   $$V_{\text{est}} = \left(N_{\text{Buko}} \times R_{\text{Buko}}\right) + \left(N_{\text{Malauhog}} \times R_{\text{Malauhog}}\right) + \left(N_{\text{Bungi}} \times R_{\text{Bungi}}\right)$$
   where $N_s$ is the coconut count for stage $s$ and $R_s$ is the configured unit buying rate (PHP/nut).
2. **Commercial Price Variance / Leakage ($\Delta V$):**
   When an aggregator settles a delivery with a buyer or farmer at an actual paid amount $V_{\text{actual}}$, the Web Dashboard's **Batch Settlement & Profit Reconciliation Engine** computes the financial variance resulting from subjective manual misgrading:
   $$\Delta V = V_{\text{est}} - V_{\text{actual}}$$
   - If $\Delta V > 0$: **Revenue Leakage / Underpayment** (high-value *Buko* nuts were manually downgraded).
   - If $\Delta V < 0$: **Overpayment Loss** (premature *Malauhog* or *Bungi* rejects were overpaid at *Buko* rates).

---

## 🖥️ 4. Updated System Features to Describe in Section 5.3 (Prototype & Final System UI)

When updating **Section 5.3 (Description of Prototype / Final System)** and **Figures 7–19**, make sure the captions and text describe these implemented `v1.4.0` modules:

### Mobile App (Flutter — `v1.4.0` Build 12)
1. **Home Screen (`HomeScreen`)**:
   - Displays **Active Delivery Session Card** (Farmer name, batch code, total coconuts scanned, live payout in PHP), **Total Scans / Unsynced Counter**, **One-Tap Cloud Sync Button** (with exponential retry), and **Recent Scans History**.
2. **Step 1: Visual Capture (`VisualScanScreen`)**:
   - Guides user to frame a single coconut husk inside the bounding guide with a **Cluster (*Bungkos*) Sampling Badge** reminding the sorter that 1 nut represents its harvested cluster.
3. **Step 2: Acoustic Capture (`AcousticScanScreen`)**:
   - Records 4.0 seconds of raw `22,050 Hz` PCM audio while the user taps the coconut 3–4 times, immediately generating and previewing the on-device `magma` Mel-spectrogram.
4. **Step 3: Fused Result & Bungkos Input (`ScanResultScreen`)**:
   - Displays the fused classification (**Buko / Mature**, **Malauhog / Premature**, or **Unrecognized / Scan Invalid**), individual **Visual (30%)** and **Acoustic (70%)** confidence bars, an interactive **Bungkos Coconut Count (`bunch_count`) Selector** (`8, 10, 12, 15` chips or custom count), and a **Save / Discard** workflow.
5. **Farmer Delivery Batch & Payout Voucher (`BatchSessionScreen`)**:
   - Allows aggregators to start a named farmer delivery session, set buying rates per piece (`₱/pc`), track live counts per grade, and generate a **Shareable Digital Delivery Voucher / Receipt** to eliminate pricing disputes.
6. **Settings & Multi-Operator Profile (`SettingsScreen`)**:
   - Includes **Field Operator Account Login**, **Server URL Configuration with Automatic URL Sanitizer**, **Unique Hardware Device ID (`device_id`)**, and **Instant English / Tagalog (`EN / TL`) Language Toggle**.

### Web Dashboard (Django + Docker — `v1.4.0`)
1. **Overview & Analytics Tab (`tab_analytics.html`)**:
   - Displays 4 real-time KPI cards (**Total Graded Coconuts** with **Sampled Bunches** subtitle, **Buko / Marketable Volume**, **Malauhog / Premature Volume**, and **Synchronized Devices**), an **Estimated Valuation Engine** with customizable PHP market rates, **Batch Settlement & Profit Reconciliation (Commercial Leakage Calculator)**, and Chart.js visualizations (**Maturity Stage Distribution Doughnut Chart** & **7-Day Grading Trend Bar Chart**).
2. **Grading Logs Tab (`tab_logs.html`)**:
   - Features **Live 3-Second Auto-Polling**, search and stage filtering (`Mature`, `Premature`, `Overmature`, `Unrecognized`), **Bungkos Count Badge (`X coconuts (1 bungkos)`)**, **Visual vs. Acoustic Confidence Progress Bars**, **Device / Operator Attribution**, and an **Inspection Modal** that plays back the synced 4-second `.wav` audio alongside the captured coconut image.
3. **Settings & Operator Management Tab (`tab_settings.html`)**:
   - Features **Editable Farm Owner Profile**, **Field Operator Account Management** (create, toggle active/inactive, reset password, delete), **Synchronized Hardware Devices Table**, and an **Install Mobile App (Android) Card** with direct APK download and **Scan-to-Install QR Code Modal**.

---

## ✅ 5. Checklist for Seann Before Final Manuscript Submission
- [ ] Global Find & Replace `YOLOv11` $\rightarrow$ **`YOLOv8-cls (TensorFlow Lite)`**.
- [ ] Update Abstract, Introduction, Conceptual Framework (Fig. 3), and Software Requirements (Table 2) to reflect **on-device TFLite inference** and **Docker + Cloudflare Tunnel deployment** instead of Vercel.
- [ ] Add the **70% Acoustic / 30% Visual Late-Fusion Equation** and its agricultural justification (visual similarity of green husks vs. acoustic resonance of internal meat thickness).
- [ ] Add the **3-Gate Out-of-Distribution (OOD) Validation Pipeline** description (Camera HSV/Texture Gate + Spectrogram Vertical Tap-Stripe Gate + Softmax Temperature Scaling $T=1.6$).
- [ ] Add the **Bungkos (Cluster) Representative Sampling** explanation and volume summation formula.
- [ ] Replace old Figma prototype screenshots (Figs. 7–19) with screenshots of the live `v1.4.0` Web Dashboard and Android App.
