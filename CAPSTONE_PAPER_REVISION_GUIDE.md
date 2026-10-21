# NiyoSense Capstone Paper Revision & Alignment Guide (v1.5.0)
**Prepared for:** Seann Yves Saracho (Manuscript & Documentation Lead)  
**Authors:** Christian Louis Bolea, Wayne Yzon Nagares, Seann Yves Saracho  
**Adviser:** Engr. Roselyn A. Maaño | **Technical Mentor / Panelist:** Prof. Eleazar Salanda  
**Primary Stakeholder / Beneficiary:** Dr. Nona D. Nagares (Coconut Plantation Owner, Quezon Province)  
**System Version:** `v1.5.0` (Build 22 — Production Cloud Release)
**Live Cloud URL:** [https://niyosense.me](https://niyosense.me) | **APK CDN:** [GitHub Release v1.5.0](https://github.com/Cbolea23/niyosense-capstone/releases/tag/v1.5.0)

---

## 🚨 CRITICAL PARADIGM SHIFTS FOR SEANN (READ FIRST!)

Before editing the manuscript, note these **two major panel-mandated shifts** from the original Capstone 1 Proposal Paper:

### 1. Target Beneficiary Shift: From "Small-Scale Aggregators" $\rightarrow$ **"Coconut Plantation Owners and Farm Managers"**
* **Old Paper:** Targeted *"Small-Scale Coconut Aggregators"* and labeled the mobile user as *"Aggregator"*.
* **New Revised Paper (`v1.4.0`):** Targets **Coconut Plantation Owners and Farm Managers** (such as our primary stakeholder, Dr. Nona D. Nagares) and their **Field Operators / Sorters (*Mambubuko*)**.
  * **Plantation Owner / Farm Manager (Web Dashboard):** Monitors total plantation harvest volume by *bungkos* (clusters), tracks **Estimated Harvest Valuation**, audits **Commercial Batch Settlement & Profit Reconciliation (Price Variance / Leakage)** when selling or paying out harvests, and manages **Field Operator accounts & synchronized farm devices**.
  * **Field Operator / Sorter (Mobile App):** Uses the offline-first mobile app in the plantation field to scan harvested *bungkos*, record delivery batches, and generate digital harvest receipts.

### 2. Model Terminology Shift: From "Multimodal Fusion" $\rightarrow$ **"Dual-Model Audio-Visual Classification Architecture"**
* **Old Paper:** Described a single *"Multimodal Fusion Model"* using YOLOv11 + Python Librosa.
* **New Revised Paper (`v1.4.0`):** Must be described as a **Dual-Model Audio-Visual Machine Learning Architecture** (NOT a single fused neural network):
  * **Model 1 — Visual Husk Model (`img_best_v2.tflite`):** A standalone **YOLOv8-cls** convolutional neural network trained on `320×320` coconut husk images.
  * **Model 2 — Acoustic Spectrogram Model (`spec_best_v2.tflite`):** A second standalone **YOLOv8-cls** convolutional neural network trained on `320×320` Mel-spectrogram images generated on-device from 4.0-second coconut knocking audio.
  * **Dual-Model Weighted Decision Combiner (70% Acoustic / 30% Visual):** Both models run independently on-device via TensorFlow Lite (`tflite_flutter`), and their calibrated probability outputs are combined via a deterministic **70% Acoustic / 30% Visual weighted decision rule** ($P_{\text{final}} = 0.70 \cdot P_{\text{audio}} + 0.30 \cdot P_{\text{visual}}$).

---

## 🔄 1. Executive Summary Matrix: Old Paper vs. New Revised Paper (`v1.4.0`)

| Manuscript Section / Topic | What Was Written in Old Paper (Capstone 1) | What Must Be Written in New Paper (`v1.4.0` Capstone 2) |
| :--- | :--- | :--- |
| **Research Title & Target Users** | *"…using Multimodal Audio-Visual Machine Learning for Small-Scale Coconut Aggregators"* | *"NiyoSense: Development of a Web and Mobile Coconut Maturity Profiling and Grading System using **Dual-Model** Audio-Visual Machine Learning for **Coconut Plantation Owners and Farm Managers**"* (or keep approved title if locked by registrar, while shifting all body text to **Plantation Owners, Farm Managers, and Field Operators**). |
| **ML Architecture Terminology** | Called *"Multimodal Fusion"* with YOLOv11 + server-side Python Librosa | **Dual-Model On-Device YOLOv8-cls Architecture (`img_best_v2.tflite` & `spec_best_v2.tflite`)** running **100% offline on the smartphone** via `tflite_flutter`, paired with a custom **Pure-Dart STFT & Slaney Mel-Spectrogram DSP Engine (`SpectrogramService.dart`)**. |
| **Input Tensor Format** | `[1, 3, 224, 224]` NCHW or unspecified | **`[1, 320, 320, 3]` NHWC RGB Float32** normalized to `[0.0, 1.0]` for both the Visual Husk model and the Acoustic Mel-Spectrogram model. |
| **Maturity Classes** | 3 classes (`Premature`, `Mature`, `Overmature`) + `50` samples each (`150` total) | **2 Target Young Coconut Classes** (`0: Buko` [Marketable / Mature Young Coconut with firm meat] vs. `1: Malauhog` [Premature / Mucus-like thin meat]) + **Deterministic Out-of-Distribution (`Unrecognized`) Rejection State** via a 3-Gate Pre-Inference Validation Pipeline. |
| **Dual-Model Decision Weighting** | Unspecified or `60% Visual / 40% Audio` fusion | **70% Acoustic / 30% Visual Dual-Model Weighted Decision Rule** ($P_{\text{final}} = 0.70 \cdot P_{\text{audio}} + 0.30 \cdot P_{\text{visual}}$). **Justification:** External green husks of *Buko* and *Malauhog* are visually near-identical in plantation piles, whereas internal endosperm meat thickness and water cavity resonance produce distinct acoustic knock signatures. |
| **Out-of-Distribution (OOD) / Non-Coconut Handling** | None (relied on raw CNN output) | **3-Gate Deterministic Pre-Inference & Post-Inference Validation Pipeline** (Gate 1: `64×64` HSV Husk Color + Luminance + Sobel Grass/Foliage Edge-Roughness Gate; Gate 2: `64×64` Spectrogram Vertical Tap-Stripe Counter requiring `2–4` knocks; Gate 3: Softmax Temperature Scaling $T=1.6$, `96.5%` confidence cap, and Acoustic-Dominant Cross-Model Verification). |
| **Audio Recording Format & Preprocessing** | Recorded in `.M4A` format indoors | Recorded in **uncompressed 16-bit PCM `.WAV` (`22,050 Hz`, mono, 4.0 seconds)** using `AndroidAudioSource.unprocessed` (hardware AGC/Noise-Suppression disabled), followed by a **300 Hz High-Pass Filter**, **1.5s Peak-Window Auto-Centering**, **Hann STFT (`n_fft=2048, hop=512`)**, **128 Slaney Mel bands**, **$-80\text{ dB}$ to $0\text{ dB}$ normalization**, and **Matplotlib `magma` colormap**. |
| **Post-Harvest Sampling Unit** | Individual coconut per scan (`1 scan = 1 nut`) | **Bungkos (Cluster) Representative Sampling (`bunch_count`)**: In real Quezon Province plantation harvests, coconuts are cut and graded by cluster (*bungkos*, typically 8–15 nuts per bunch). Scanning 1 representative nut profiles the entire *bungkos*, and the field operator inputs the exact **Bungkos Coconut Count (`bunch_count`)** so all dashboard volume KPIs, charts, and financial valuations track both **Total Coconuts** and **Sampled Bunches**. |
| **Plantation Management & Financial Features** | Only mentioned basic aggregator inventory & grading logs | **Plantation Harvest Batch Session & Tally Voucher System** (mobile) + **Estimated Harvest Valuation Engine & Commercial Settlement / Profit Reconciliation (Price Variance / Leakage Detection)** (web dashboard for Plantation Owners & Farm Managers). |
| **Multi-Device & Multi-Operator Architecture** | Mentioned single user / Vercel + Neon serverless | **Render Web Services + Render Managed PostgreSQL + Cloudinary + Cloudflare Edge (`https://niyosense.me`) + GitHub Releases CDN** with **30-Day Multi-Device JWT Authentication**, **Persistent Relational DB & Media Decoupling**, **Unique Hardware Device ID (`device_id`)**, and **Role-Based Field Operator Accounts**. |

---

## 📖 2. Chapter-by-Chapter Manuscript Revisions (Exact Replacements)

### 2.1 Abstract (Lines 162–164 of Old Paper)
**What Was Wrong in Old Abstract:**
- Used *"Small-scale coconut aggregators"*, *"YOLOv11"*, and *"late-fusion classification architecture"*.

**Ready-to-Paste Revised Abstract (Aligned to Dual-Model & Plantation Owners/Managers):**
> Coconut plantation owners and farm managers in the Philippines rely on subjective manual tapping and visual inspection by field sorters for post-harvest maturity grading, leading to inconsistent quality assessment, pricing disputes, and post-harvest financial losses. Existing digital solutions lack integrated, offline-capable mobile tools that evaluate both visual husk traits and internal acoustic resonance for accurate field sorting. This study develops **NiyoSense**, a web and mobile coconut maturity profiling and grading system that utilizes a **dual-model audio-visual machine learning architecture** to provide standardized, objective harvest grading for coconut plantation owners and farm managers. The system deploys two independent **YOLOv8-cls** convolutional neural networks exported to **TensorFlow Lite (`320×320` Float32)**: a visual model for outer husk classification and an acoustic model for Mel-spectrogram classification, supported by a pure-Dart Short-Time Fourier Transform (STFT) signal processing pipeline that converts 4-second raw `.wav` knock recordings into 128-band Slaney Mel-spectrograms on-device. Because external green husks of *Buko* (mature marketable young coconut) and *Malauhog* (premature mucus-like coconut) are visually similar while internal meat thickness alters acoustic resonance, predictions from the two models are combined via an **acoustic-dominant 70/30 dual-model decision rule ($0.70 \cdot P_{\text{audio}} + 0.30 \cdot P_{\text{visual}}$)** protected by a **3-Gate Out-of-Distribution (OOD) Validation Pipeline** and Softmax temperature scaling ($T = 1.6$). Built with Flutter and local SQLite storage, the mobile application enables field operators to perform 100% offline grading, **cluster (*bungkos*) volume accounting**, and harvest batch tallying, while a Dockerized Django web dashboard empowers plantation owners and managers with concurrent multi-device synchronization, real-time harvest analytics, estimated valuation, and commercial settlement reconciliation. Evaluation against ISO/IEC 25010 standards validates the system's functional suitability, performance efficiency, usability, and reliability for plantation post-harvest management.
>
> **Index Terms:** *Acoustic signal processing, agricultural decision support system, bungkos cluster sampling, coconut maturity grading, dual-model machine learning, Mel-spectrogram, plantation management, TensorFlow Lite, YOLOv8-cls.*

---

### 2.2 Chapter 2: Introduction — Context, Objectives, Significance & Scope (Lines 166–187 of Old Paper)

#### A. Project Context & Purpose (Sections 2.1 & 2.2)
- Replace references to *"small-scale aggregators"* with **"coconut plantation owners, farm managers, and their field sorting teams"**.
- Replace *"multimodal fusion"* with **"dual-model audio-visual classification"** where two specialized YOLOv8-cls models independently analyze the visual husk and the acoustic knocking Mel-spectrogram.

#### B. Main and Specific Objectives (Section 2.3)
- **Main Objective:**
  > To design, develop, and evaluate a Web and Mobile Coconut Maturity Profiling and Grading System using **Dual-Model Audio-Visual Machine Learning**, aiming to provide **coconut plantation owners, farm managers, and field operators** with an accurate, offline-capable tool for determining young coconut maturity stages (*Buko* vs. *Malauhog*) and auditing harvest value during the post-harvest sorting phase.
- **Specific Objectives:**
  1. **Dataset Preparation:** To gather and preprocess a paired audio-visual dataset of young coconuts from the stakeholder's plantation in Quezon Province categorized into **Buko** (mature young coconut with firm, marketable meat) and **Malauhog** (premature young coconut with thin, mucus-like meat), capturing visual husk images and standardized 4.0-second uncompressed `.wav` acoustic tapping signals (3–4 taps per sample) converted into `320×320` Mel-spectrograms (`magma` colormap).
  2. **UI/UX Prototyping:** To design the user interface for both the mobile field-scanning application and the centralized plantation management web dashboard.
  3. **Dual-Model Development:** To develop and train **two independent YOLOv8-cls deep learning models** (`img_best_v2.tflite` for visual husk images and `spec_best_v2.tflite` for acoustic Mel-spectrograms) integrated with a **3-Gate Out-of-Distribution (OOD) Pre-Inference Validation Pipeline** and a **70% Acoustic / 30% Visual Dual-Model Weighted Decision Combiner**.
  4. **Mobile & Web System Development:** To develop the offline-first Flutter mobile application with local SQLite storage, **Bungkos (Cluster) coconut count input (`bunch_count`)**, **Harvest Batch Session & Voucher generation**, and **English/Tagalog localization** for field operators, alongside a Dockerized Django Web Dashboard that allows **plantation owners and farm managers** to monitor multi-device grading logs, calculate **Estimated Harvest Valuation**, and perform **Commercial Settlement & Profit Reconciliation**.
  5. **Testing & Evaluation:** To test the system using the black-box testing method and evaluate its quality characteristics according to the **ISO/IEC 25010** standard.

#### C. Significance of the Research (Section 2.4 — Lines 180–184)
Replace the old beneficiary list with:
- **Coconut Plantation Owners and Farm Managers:** Provides a centralized Web Dashboard for real-time harvest inventory tracking by cluster (*bungkos*), automated market valuation, and commercial settlement reconciliation to prevent revenue leakage caused by subjective manual misgrading.
- **Field Operators and Harvesters (*Mambubuko*):** Provides an objective, offline-capable mobile scanning tool that removes guesswork and fatigue during post-harvest sorting and produces transparent batch tally receipts.
- **Coconut Buyers and Supply Chain Stakeholders:** Establishes a consistent, verifiable grading standard between **Buko** and **Malauhog** deliveries.
- **Future Researchers:** Serves as a technical reference for deploying lightweight, **dual-model on-device audio-visual deep learning (`YOLOv8-cls` + pure-Dart STFT Mel-spectrograms)** in rural agricultural environments.

#### D. Scope and Limitation (Section 2.5 — Lines 185–187)
- **Target Users & Locale:** Designed for **coconut plantation owners, farm managers, and field operators** in Quezon Province (specifically validated with the plantation operations of Dr. Nona D. Nagares).
- **Dual-Model Binary Classification (*Buko* vs. *Malauhog*):** The on-device dual-model pipeline classifies harvested young coconuts into **Buko (Mature / Marketable Young Coconut)** and **Malauhog (Premature / Mucus-like Young Coconut)**, while also supporting commercial tally entry for **Bungi (Reject / Damaged)** nuts during batch settlement.
- **Bungkos (Cluster) Sampling Methodology:** Following standard plantation harvesting practice where nuts are cut by bunch (*bungkos*), scanning one representative coconut profiles the entire *bungkos*, and the operator inputs the cluster's nut count (`bunch_count`, typically 8–15 pieces).
- **Environmental Guardrails:** The system enforces **Gate 1 (Camera Pixel & Texture Gate)** and **Gate 2 (Spectrogram Tap-Stripe Gate)** to automatically flag invalid captures as `Unrecognized` and prompt a re-scan.

---

### 2.3 Chapter 3: Theoretical & Conceptual Framework (Lines 189–287 of Old Paper)
1. **Section 3.1 (Concept Map) & Section 3.4 (Conceptual Framework - Fig. 3):**
   - Replace `YOLOv11` $\rightarrow$ **`Dual YOLOv8-cls Models (TensorFlow Lite)`**.
   - Replace `Multimodal Fusion` $\rightarrow$ **`Dual-Model Audio-Visual Classification (70% Acoustic / 30% Visual)`**.
   - Replace `Python Librosa (Backend)` $\rightarrow$ **`On-Device Dart STFT & Slaney Mel-Spectrogram Engine (SpectrogramService)`**.
   - Replace `Small-Scale Aggregator` $\rightarrow$ **`Plantation Owner / Farm Manager (Web) & Field Operator (Mobile)`**.
   - Replace `Vercel` $\rightarrow$ **`Render Web Services + Cloudflare Edge (https://niyosense.me) + GitHub Releases CDN`**.
2. **Section 3.5 (Definition of Terms — Lines 259–271):**
   - **Remove/Replace** *"Multimodal Fusion"* with:
     - **Dual-Model Architecture:** An AI system design utilizing two separate, specialized deep learning models—one trained on visual coconut husk images and one trained on acoustic Mel-spectrogram images—whose probability outputs are combined using a weighted decision rule.
     - **Buko:** Marketable young coconut stage characterized by a firm, spoon-soft endosperm meat layer and a resonant acoustic tap signature.
     - **Malauhog:** Premature young coconut stage characterized by a very thin, translucent, mucus-like endosperm layer and a dull/dampened acoustic tap signature.
     - **Bungkos (Cluster Sampling):** A harvested bunch/cluster of coconuts from a single tree spadix (typically 8–15 nuts) that shares a uniform physiological maturity stage.
     - **Mel-Spectrogram:** A time-frequency visual representation of an acoustic signal mapped onto the perceptual Mel frequency scale and rendered using the `magma` color lookup table for CNN classification.
     - **Plantation Owner / Farm Manager:** The primary administrative user of the NiyoSense Web Dashboard responsible for overseeing harvest grading logs, operator accounts, batch valuations, and commercial settlement reconciliation.
     - **Field Operator:** The mobile application user on the plantation who captures visual and acoustic coconut scans, inputs *bungkos* nut counts, and synchronizes field logs to the central dashboard.

---

### 2.4 Chapter 4: Operational Framework — Software & Data Tables (Lines 288–371 of Old Paper)
**Update Table 2 (Software Requirements):**
- **Machine Learning:** `Ultralytics YOLOv8-cls` & `TensorFlow Lite (tflite_flutter ^0.10.4)` — Used to train and execute two independent on-device `320×320` classification models (`img_best_v2.tflite` and `spec_best_v2.tflite`).
- **Audio Signal Processing:** `Python Librosa` (for offline training dataset preparation) & **Custom Pure-Dart DSP (`SpectrogramService.dart`)** — Performs on-device 300 Hz high-pass filtering, 1.5s peak-window centering, Hann STFT (`n_fft=2048, hop=512`), and 128 Slaney Mel filterbanks.
- **Web/Backend Hosting & Deployment:** `Render Web Services + Cloudflare Edge (https://niyosense.me) + GitHub Releases CDN` — Replaces Vercel; provides 24/7 containerized backend deployment with persistent fixture loading (`initial_data.json`), SSL encryption, and high-speed global APK delivery.
- **Database:** `SQLite (sqflite)` on mobile for 100% offline edge storage; `Render Managed PostgreSQL` on the cloud backend for permanent multi-device sync, with `Cloudinary` for media BLOB storage.

---

## 🔬 3. Chapter 5: Complete Technical Methodology & Mathematical Formulas (New Section Content for Paper)

Include these **5 core technical subsections and equations** in **Chapter 5 (Description of Methods or Approach / System Architecture)**:

### 3.1 On-Device Acoustic Signal Processing Pipeline (`SpectrogramService.dart`)
When the field operator taps a coconut 3–4 times during the 4.0-second recording window, the mobile application captures raw audio and transforms it into a `320×320` RGB Mel-spectrogram image entirely offline:
1. **Unprocessed Hardware Capture:** Recorded at `22,050 Hz` mono 16-bit PCM (`.wav`) using `AndroidAudioSource.unprocessed` (`autoGain: false`, `noiseSuppress: false`, `echoCancel: false`) so Android OS voice filters do not suppress percussive wood/knuckle knocks.
2. **First-Order High-Pass Filter ($f_c = 300\text{ Hz}$):** Removes low-frequency wind rumble, hand-handling thuds, and ambient hum:
   $$y[n] = \alpha \left(y[n-1] + x[n] - x[n-1]\right), \quad \alpha = \frac{RC}{RC + \Delta t}, \quad RC = \frac{1}{2\pi \cdot 300}$$
3. **Peak-Window Auto-Centering (1.5-Second Active Window):** Scans the filtered waveform using a `1.5s` sliding window (`step = 0.05s`) to locate the highest acoustic energy segment containing the 3–4 knocks and centers it before spectral conversion.
4. **Short-Time Fourier Transform (STFT) & Slaney Mel-Filterbank:** Applies a periodic Hann window ($N_{\text{fft}} = 2048$, $\text{hop} = 512$) and maps power spectra onto $M = 128$ triangular Slaney-normalized Mel bands ($0\text{ Hz}$ to $11,025\text{ Hz}$), converting power to decibels normalized to $[-80\text{ dB}, 0\text{ dB}]$ and rendering pixels via the 256-entry Matplotlib `magma` color lookup table at `320×320` resolution.

---

### 3.2 3-Gate Pre-Inference & Post-Inference Out-of-Distribution (OOD) Validation Pipeline
Because standard Softmax classification networks (`YOLOv8-cls`) trained on closed-set classes (*Buko* vs. *Malauhog*) can assign high probabilities to out-of-distribution inputs (e.g., grass, concrete, faces, or silent/noisy audio) without adding a third "non-coconut" class that could degrade visual feature boundaries, NiyoSense implements a deterministic **3-Gate Validation Pipeline** in [`ModelService.dart`](file:///d:/desktop/GITHUB/niyosense-capstone/lib/services/model_service.dart):

- **Controlled Grading Station Environmental Guardrail Protocol:**
  Because the two specialized neural networks (`img_best_v2.tflite` and `spec_best_v2.tflite`) are strictly closed-set **2-class models** (`0: Buko` vs. `1: Malauhog`) with no third class for non-coconut objects or ambient sounds, post-harvest grading is conducted exclusively by the **Field Manager** at a **Controlled Grading Station** (shaded inspection table, neutral matte background, quiet room, standardized 3-knock tapping protocol). Pre-inference guardrails (Gates 1 & 2) deterministically reject any non-coconut input before the model can be queried.

- **Gate 1: Controlled Station Visual Husk & Texture Gate (`64×64` Downsampled RGB):**
  1. *Station Lighting Exposure Window:* Rejects dark station shadows, covered lenses, or washed-out flash glare if mean luminance $\mu_Y \notin [35.0, 230.0]$ or standard deviation $\sigma_Y < 8.0$.
  2. *Authentic Coconut Husk HSV Window:* Restricts valid husk chromaticity to natural green and golden-olive hues: $H \in [36^\circ, 148^\circ]$, $S \in [0.15, 0.88]$, $V \in [0.18, 0.92]$.
  3. *Core Foreign Color Rejection:* Checks the core 30% ROI for foreign saturated colors ($S > 0.40$ with $H < 30^\circ$ or $H \in [175^\circ, 340^\circ]$, rejecting human skin tones, cardboard, wooden tables, blue jeans, and synthetic plastics).
  4. *Husk Coverage & Aspect Ratio:* Requires $\ge 45\%$ husk coverage in the Center 60% ROI and $\ge 60\%$ in the Core 30% ROI, with an aspect ratio of $0.65–1.55$ to prevent thin elongated non-coconut objects.
  5. *3D Spherical Shading & Natural Texture:* Requires green luminance standard deviation $\sigma_{\text{greenLum}} \ge 6.5$ (verifying natural 3D spherical lighting gradients across the nut) and Sobel gradient edge roughness of $2.2–32.0$ (rejecting flat 2D printouts, perfectly smooth balls, or high-frequency grass/foliage).
  6. *Hard Shutter Lock:* The Live Reticle HUD in `visual_scan_screen.dart` strictly blocks shutter release when alignment is Red (Tier 0), preventing out-of-spec photos from ever reaching inference.

- **Gate 2: Acoustic Signal Processing & Standard Operating Procedure (SOP):**
  1. *First-Order 300 Hz High-Pass Filter:* Applied to raw 22,050 Hz PCM audio prior to STFT padding to suppress low-frequency hand handling noise, desk bumps, and ambient room rumble.
  2. *Mel-Spectrogram Generation:* Preprocesses the 4.0-second `.wav` into a calibrated 128-band Slaney Mel-spectrogram on-device (`320×320` Float32, `magma` colormap).
  3. *Standard Operating Procedure (SOP) Protocol:* To prevent fragile false-rejection dropouts caused by microphone hardware differences across smartphones, acoustic validation relies on a standardized on-screen SOP instructing the Field Manager to hold the device 5–10 cm from the coconut and firmly knock 3 times on the coconut equator (~1 second apart).

- **Gate 3: Calibrated Softmax Temperature Scaling ($T = 1.6$), Confidence Cap (`96.5%`), & Dual-Model Late Fusion:**
  1. *Softmax Temperature Scaling:* Raw YOLOv8-cls output probabilities are softened ($T = 1.6$):
     $$\hat{P}_i = \frac{p_i^{1/T}}{\sum_{j} p_j^{1/T}}, \quad T = 1.6$$
  2. *Confidence Cap:* Displayed confidence is capped at **96.5%** to prevent false certainty.
  3. *Dual-Model Late Fusion Combiner ($0.70 \cdot P_{\text{audio}} + 0.30 \cdot P_{\text{visual}}$):* Combines acoustic resonance with visual husk traits without artificial disagreement vetoes, allowing the model's true acoustic weights to guide maturity grading.
  4. *Mandatory Dual-Modality:* Both visual inspection and acoustic tapping are mandatory for every grading session.

---

### 3.3 Acoustic-Dominant 70/30 Dual-Model Decision Formula
In plantation field conditions, *Buko* and *Malauhog* harvested from green bunches exhibit nearly identical outer husk color and shape, whereas internal meat thickness and water cavity volume strongly modulate acoustic knock resonance. Therefore, the dual-model decision combiner applies a **70% Acoustic / 30% Visual weighting** across the two independent YOLOv8-cls models:
$$P_{\text{final}}(c) = 0.70 \cdot \hat{P}_{\text{audio}}(c) + 0.30 \cdot \hat{P}_{\text{visual}}(c), \quad c \in \{\text{Buko}, \text{Malauhog}\}$$
$$\text{Predicted Stage} = \arg\max_{c} P_{\text{final}}(c)$$

---

### 3.3.1 Controlled Grading Station Operator Guide (Defense Alignment)
To reinforce the scope and limitations of the dual-model closed-set architecture (`Buko` vs. `Malauhog`, with no 3rd class) during user evaluation and defense demonstrations, the mobile application introduces an interactive 4-page **Controlled Inspection Guide** (`ScanGuideDialog`) triggered before camera capture:
1. **Operator Role & Station Gating:** Establishes that the tool is operated strictly by the **Field Manager** at a controlled grading station (indoor/shaded table, neutral matte background, quiet room), not by random field hands in uncontrolled outdoor conditions.
2. **Visual Object Differentiation (Scan vs. Do Not Scan):** Displays side-by-side reference images of valid green young coconuts versus non-coconut green distractors (green fruits, green plastic tables, green microfiber fabrics) with explicit warnings that non-coconut green objects are out-of-scope.
3. **Controlled Station Do's and Don'ts:** Outlines framing best practices (single nut, circular reticle lock-on, flash usage under shadows, silence during audio capture).
4. **Animated Acoustic Tapping Protocol:** Features an interactive animated knocker illustrating phone microphone distance (5–10 cm from the coconut equator) and the 3-knock cadence (~1 second apart), supported by a "Don't show again" preference and an on-demand "? Guide" button in the camera viewfinder.

### 3.4 Bungkos (Cluster) Sampling & Plantation Volume Accounting Formula
In coconut plantation operations, harvesters cut entire clusters (*bungkos*) from a tree spadix. Since nuts within a single *bungkos* develop simultaneously, scanning one representative coconut grades the entire cluster. On `ScanResultScreen`, the field operator inputs the cluster's nut count $n_i$ (`bunch_count`, default `10`, quick-select chips `8, 10, 12, 15`). Total graded volume across $K$ scanned clusters is computed as:
$$\text{Total Graded Coconuts} = \sum_{i=1}^{K} n_i, \qquad \text{Total Sampled Bunches} = K$$
$$\text{Stage Volume}(s) = \sum_{i \in \Omega_s} n_i$$
where $\Omega_s$ is the set of scanned clusters classified under maturity stage $s$.

---

### 3.5 Plantation Harvest Valuation & Commercial Settlement Reconciliation Formulas
1. **Estimated Harvest Valuation ($V_{\text{est}}$):**
   $$V_{\text{est}} = \left(N_{\text{Buko}} \times R_{\text{Buko}}\right) + \left(N_{\text{Malauhog}} \times R_{\text{Malauhog}}\right) + \left(N_{\text{Bungi}} \times R_{\text{Bungi}}\right)$$
   where $N_s$ is the coconut count for stage $s$ and $R_s$ is the configured unit market rate (PHP/nut).
2. **Commercial Price Variance / Leakage ($\Delta V$):**
   When a plantation owner or farm manager settles a harvest batch against an actual buyer payout $V_{\text{actual}}$, the Web Dashboard's **Batch Settlement & Profit Reconciliation Engine** computes the financial variance resulting from subjective manual misgrading:
   $$\Delta V = V_{\text{est}} - V_{\text{actual}}$$
   - If $\Delta V > 0$: **Revenue Leakage / Underpayment** (high-value *Buko* nuts were manually downgraded during buyer sorting).
   - If $\Delta V < 0$: **Overpayment Variance** (premature *Malauhog* or *Bungi* rejects were priced at *Buko* rates).

---

## 🖥️ 4. Updated User Roles & System Features for Section 5.2 & 5.3 (Diagrams & UI Captions)

### Update Fig. 5 (Use Case Diagram) & Fig. 6 (User Flow Diagram):
- **Role 1: Field Operator / Sorter (Mobile App User)** — Logs in with operator credentials, captures Visual Husk image + 4.0s Acoustic Knocking audio offline, views Dual-Model classification (*Buko* vs. *Malauhog*), inputs **Bungkos Coconut Count (`bunch_count`)**, records **Harvest Delivery Batch Sessions**, and synchronizes logs to the plantation server when connected.
- **Role 2: Plantation Owner / Farm Manager (Web Dashboard Administrator)** — Monitors real-time plantation harvest KPIs (Total Graded Coconuts & Sampled Bunches), configures unit market rates in the **Estimated Valuation Engine**, audits buyer/farmer payouts in the **Batch Settlement & Profit Reconciliation Calculator**, inspects synced Grading Logs with `.wav` audio playback and dual-model confidence bars, and manages **Field Operator Accounts & Synchronized Farm Devices**.

### Mobile App UI Screens (Flutter — `v1.4.0` Build 12)
1. **Home Screen (`HomeScreen`)**: Active Harvest Batch Session card, Total Scans / Unsynced counter, One-Tap Cloud Sync button, and Recent Scans list.
2. **Step 1: Visual Capture (`VisualScanScreen`)**: Camera framing guide with **Cluster (*Bungkos*) Sampling Badge**.
3. **Step 2: Acoustic Capture (`AcousticScanScreen`)**: 4.0-second `22,050 Hz` unprocessed `.wav` recording with instant on-device `magma` Mel-spectrogram preview.
4. **Step 3: Dual-Model Result & Bungkos Input (`ScanResultScreen`)**: Displays final classification (**Buko / Mature**, **Malauhog / Premature**, or **Unrecognized / Scan Invalid**), separate **Visual Model (30%)** and **Acoustic Model (70%)** confidence bars, **Bungkos Coconut Count (`bunch_count`) Selector** (`8, 10, 12, 15`), and Save/Discard controls.
5. **Harvest Batch & Tally Voucher (`BatchSessionScreen`)**: Per-batch piece-rate configuration (`₱/pc`), live grade tallies, and shareable digital harvest voucher/receipt.
6. **Settings & Operator Profile (`SettingsScreen`)**: Field Operator login, Server URL with auto-sanitizer, Unique Hardware Device ID (`device_id`), and reactive **English / Tagalog (`EN / TL`)** toggle.

### Web Dashboard UI Tabs (Django + Docker — `v1.4.0`)
1. **Overview & Analytics Tab (`tab_analytics.html`)**: 4 KPI cards (**Total Graded Coconuts** + **Sampled Bunches**, **Buko Volume**, **Malauhog Volume**, **Synchronized Devices**), **Estimated Valuation Engine**, **Batch Settlement & Profit Reconciliation**, and Chart.js Doughnut & 7-Day Trend charts.
2. **Grading Logs Tab (`tab_logs.html`)**: **Live 3-Second Auto-Polling**, stage filter & search, **Bungkos Count Badge (`X coconuts (1 bungkos)`)**, **Visual vs. Acoustic Model Confidence Bars**, **Operator/Device Attribution**, and **Audio/Image Inspection Modal**.
3. **Settings & Farm Management Tab (`tab_settings.html`)**: **Editable Plantation Owner / Farm Manager Profile**, **Field Operator Account Management**, **Synchronized Hardware Devices Table**, and **Install Mobile App (Android) QR Code & Direct APK Download**.

---

## ✅ 5. Final Revision Checklist for Seann
- [ ] **Beneficiary Terminology:** Replace *"Small-Scale Coconut Aggregators"* across the manuscript with **"Coconut Plantation Owners and Farm Managers"** (for the Web Dashboard) and **"Field Operators / Sorters"** (for the Mobile App).
- [ ] **Architecture Terminology:** Replace *"Multimodal Fusion"* and *"YOLOv11"* with **"Dual-Model Audio-Visual Machine Learning Architecture"** using **two independent on-device `YOLOv8-cls` TensorFlow Lite models (`img_best_v2.tflite` and `spec_best_v2.tflite`)**.
- [ ] **70/30 Dual-Model Equation:** Include $P_{\text{final}}(c) = 0.70 \cdot \hat{P}_{\text{audio}}(c) + 0.30 \cdot \hat{P}_{\text{visual}}(c)$ and its field justification (outer green husks of *Buko* and *Malauhog* look almost identical, whereas internal meat thickness alters acoustic resonance).
- [ ] **3-Gate OOD Validation Pipeline:** Document Gate 1 (`64×64` HSV Husk + Luminance + Sobel Texture), Gate 2 (`64×64` Spectrogram Vertical Tap-Stripe Counter requiring `2–4` knocks), and Gate 3 (Softmax Temperature Scaling $T=1.6$ + `96.5%` cap).
- [ ] **Bungkos (Cluster) Sampling & Plantation Valuation:** Add the `bunch_count` cluster volume equation and the Commercial Settlement Reconciliation ($\Delta V = V_{\text{est}} - V_{\text{actual}}$) equation.
- [ ] **Deployment & Screenshots:** Update Fig. 21 (Deployment Diagram) from Vercel to **Render Web Services + Cloudflare Edge (https://niyosense.me) + GitHub Releases CDN**, and replace old Figma screenshots (Figs. 7–19) with live `v1.5.0` production screenshots.
