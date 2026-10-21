# Project Name: NiyoSense (v1.5.0 — Build 22)

**Description**: Fully offline-first, **Dual-Model Audio-Visual** coconut maturity profiling and grading system for Android devices, supported by a 24/7 cloud-deployed Django web dashboard on `https://niyosense.me` designed for **Coconut Plantation Owners and Farm Managers** to oversee cluster (*bungkos*) harvest volume, estimated valuation, commercial settlement reconciliation, and concurrent multi-device field operator synchronization.

> 📄 **Capstone References:**
> * See [`NIYOSENSE_TECHSTACK_AND_VARIANCE_REPORT.md`](NIYOSENSE_TECHSTACK_AND_VARIANCE_REPORT.md) for the complete tech stack breakdown and proposal-vs-implementation variance matrix.
> * See [`CAPSTONE_PAPER_REVISION_GUIDE.md`](CAPSTONE_PAPER_REVISION_GUIDE.md) for chapter-by-chapter manuscript revisions.
> * See [`HOW_TO_TEST_AND_EXPLAIN_BUNGKOS.md`](HOW_TO_TEST_AND_EXPLAIN_BUNGKOS.md) for the oral defense narrative on cluster (*bungkos*) representative sampling.

---

## 1. System Architecture & Tech Stack

* **Target Beneficiaries & Roles**:
  * **Plantation Owner / Farm Manager (Web Dashboard at `https://niyosense.me`)**: Oversees plantation-wide harvest volume by *bungkos* (clusters), configures market pricing in the Estimated Valuation Engine, audits buyer/sorter payouts via the Batch Settlement & Profit Reconciliation calculator, and manages Field Operator accounts & synchronized farm devices.
  * **Field Operator / Sorter (Mobile App `v1.4.5+17`)**: Performs 100% offline visual + acoustic coconut scanning in the plantation field, inputs *bungkos* nut counts (`bunch_count`), records harvest delivery batches, and syncs data to the central dashboard.
* **Mobile Frontend**: Flutter / Dart (`v1.4.5+17`, Dart SDK `^3.8.1`)
  * Operates **100% offline-first** in remote plantation environments.
  * Local database: SQLite (`sqflite`, schema with `grading_logs` and `batch_sessions`).
  * On-device Dual-Model Machine Learning: TensorFlow Lite (`tflite_flutter ^0.10.4`).
  * On-device Acoustic DSP: Custom pure-Dart STFT & 128-band Slaney Mel-Spectrogram generator (`SpectrogramService.dart`).
  * Hardware Audio Calibration: Configured with `AndroidAudioSource.unprocessed` (low-latency PCM, disabled hardware AGC/ANC) specifically tuned for modern Android hardware (e.g., Samsung Galaxy S25+).
* **Backend Dashboard & Cloud API**: Django 6.1 + Django REST Framework + Gunicorn 23.0.0 + WhiteNoise 6.9.0
  * Database: **Render Managed PostgreSQL** (`DATABASE_URL` via `dj-database-url` and `psycopg2-binary`) providing permanent cloud persistence across container lifecycle events, with embedded SQLite fallback for local development.
  * Media Storage: **Cloudinary Object Storage CDN** (`django-cloudinary-storage`) for permanent storage and streaming of coconut husk photos and acoustic tap recordings.
  * Authentication: 30-day multi-device JWT (`SIMPLE_JWT` with `BLACKLIST_AFTER_ROTATION = False`) for field operators, and session authentication for web managers.
  * Synchronization endpoint: Concurrent bulk log & media sync (`/api/v1/sync/bulk-logs/`) with 5-attempt atomic locking retry handlers.
* **Production Deployment & Cloud Infrastructure**:
  * **Render Web Services**: Containerized Docker image (`niyosense-capstone.onrender.com`) running Python 3.12, dynamic `$PORT` binding, and `/healthz` uptime health check.
  * **Render Managed PostgreSQL**: Zero-latency private network relational database (`dpg-...:5432`) hosting persistent grading logs, price settings, and user accounts.
  * **Cloudinary CDN**: Decoupled cloud storage for media BLOBs, preventing ephemeral container data loss.
  * **Cloudflare Edge**: Apex domain **`https://niyosense.me`** and `www.niyosense.me` with automatic SSL/TLS termination, HTTP/2 & HTTP/3 acceleration, and DDoS protection.
  * **GitHub Releases CDN**: Distributes the official release asset `niyosense.apk` (100.25 MB) under release tag `v1.4.5` with unthrottled global download speeds.

---

## 2. Dual-Model Architecture, 3-Gate OOD Validation & 70/30 Weighted Decision Rule

Instead of a single monolithic neural network, NiyoSense employs a **Dual-Model Audio-Visual Classification Architecture** running two independent **YOLOv8-cls** TFLite models on-device expecting **`[1, 320, 320, 3]` NHWC RGB Float32** input tensors (`0.0–1.0` normalized) with 2 target young coconut classes (`0: buko` [Mature / Marketable meat], `1: malauhog` [Premature / Mucus-like meat]):

1. **Model 1 — Visual Husk Model (`assets/models/img_best_v2.tflite`)**:
   * Standalone `YOLOv8-cls` model evaluating coconut husk visual features resized to `[1, 320, 320, 3]` NHWC RGB Float32.
2. **Model 2 — Acoustic Spectrogram Model (`assets/models/spec_best_v2.tflite`)**:
   * Standalone `YOLOv8-cls` model evaluating coconut acoustic resonance from a 4.0-second tapping `.wav` recording (`22,050 Hz`, mono PCM, recorded via `AndroidAudioSource.unprocessed`).
   * On-device preprocessing (`SpectrogramService.dart`):
     * First-order High-Pass Filter: `300 Hz` cutoff
     * Peak-Window Auto-Centering: `1.5s` active window (`0.05s` step)
     * Hann Window STFT: `n_fft = 2048`, `hop_length = 512`
     * Mel Filterbank: `128` Slaney-normalized Mel bands (`0 Hz – 11,025 Hz`)
     * Log-power normalization: `-80 dB` to `0 dB`
     * Colormap: 256-color Matplotlib `magma` LUT resized to `[1, 320, 320, 3]` Float32.
3. **3-Gate Out-of-Distribution (OOD) Validation Pipeline (	flite_service.dart & spectrogram_service.dart)**:
   * **Controlled Grading Environment Requirement**: Standardized inspection station (indoor/shaded grading table, neutral matte background, quiet acoustic setting, standard 3-tap acoustic knuckle/mallet protocol).
   * **Gate 1 (Controlled Station Visual Husk & Texture Gate on 64×64 RGB)**:
     * Lighting Exposure Window: $\\mu \\in [35.0, 230.0], \\sigma \\ge 8.0$ (rejects extreme glare, washed-out flash, or dark shadows).
     * Strict Authentic Husk HSV Range: Hue ^\\circ–148^\\circ$, Saturation .15–0.88$, Value .18–0.92$.
     * Core Foreign Color Rejection: Detects foreign colors ( > 0.40$ with  < 30^\\circ$ or  \\in [175^\\circ, 340^\\circ]$, e.g., skin, clothing, cardboard, blue/red plastics) in the center core.
     * Husk Coverage & Shape: Center 60% ROI fill $\\ge 45\%$, Core 30% ROI fill $\\ge 60\%$, Bounding Box Aspect Ratio .65–1.55$.
     * 3D Spherical Shading & Natural Texture: $\\sigma_{\\text{greenLum}} \\ge 6.5$ (verifies natural 3D spherical curvature luminance gradient) and Sobel gradient edge roughness .2–32.0$ (rejects flat prints, smooth synthetic balls, or fibrous grass/leaves).
     * Hard Shutter Lock: Live Reticle HUD blocks camera shutter release when alignment is Red (Tier 0).
   * **Gate 2 (Acoustic Signal Processing & Firm-Knock SOP)**:
     * First-order 300 Hz High-Pass Filter before STFT (suppresses low-frequency hand handling noise and room rumble).
     * Mel-Spectrogram Generation: Generates calibrated 128-band Slaney Mel-spectrogram on-device (`[1, 3, 320, 320]` Float32, `magma` colormap).
     * Firm-Knock Standard Operating Procedure (SOP): Rather than fragile, hardware-dependent threshold rejection that causes false dropouts across varying phone microphones, acoustic validation relies on a standardized on-screen SOP instructing the Field Manager to position the phone 5–10 cm away and firmly knock 3 times on the coconut equator (~1 second apart).
   * **Gate 3 (Calibrated Softmax Temperature Scaling & 70/30 Dual-Model Decision Combiner)**:
     * Softmax Temperature Scaling: $T = 1.6$, capping display confidence at $96.5\%$.
     * Dual-Model Late Fusion ($0.70 \cdot P_{\text{audio}} + 0.30 \cdot P_{\text{visual}}$): Transparently combines acoustic resonance and visual husk traits without false disagreement vetoes, allowing the acoustic model's learned weights to guide maturity grading.
     * Mandatory Dual-Modality: Both visual capture and acoustic tap recording are strictly required for every scan.
4. **Acoustic-Dominant 70/30 Dual-Model Decision Formula**:
   $$P_{\text{final}}(c) = (0.70 \times P_{\text{audio}}(c)) + (0.30 \times P_{\text{visual}}(c))$$
   * Reflects field testing showing that outer husks of *Buko* and *Malauhog* appear visually similar, whereas internal meat thickness and water cavity resonance differ distinctly under acoustic knocking.

---

## 3. Key Implemented System Capabilities (`v1.4.5`)

* **Bungkos (Cluster) Representative Sampling (`bunch_count`)**:
  * Supports real-world plantation cluster grading where 1 scanned coconut profiles an entire harvested *bungkos* (default `10` nuts, quick chips `8, 10, 12, 15`, or custom count).
  * Web Dashboard KPIs, Doughnut/Trend charts, and Valuation calculators aggregate total graded coconuts ($\sum \text{bunch\_count}$) alongside total sampled bunches.
* **Plantation Harvest Batch & Tally Voucher System**:
  * Mobile `BatchSessionScreen` tracks harvest batches, customizable unit buying prices (`₱/pc`), live grade tallies, and shareable text vouchers.
* **Web Dashboard Commercial Valuation & Settlement Reconciliation**:
  * Real-time **Estimated Valuation Engine** and **Batch Settlement / Profit Reconciliation Calculator** for plantation owners and farm managers to quantify commercial price variance and revenue leakage.
* **Concurrent Multi-Device Sync & Live Dashboard Polling**:
  * Simultaneous multi-phone syncing via SQLite WAL + 5x server atomic retry + 3x client retry, UUID-prefixed media uploads, URL sanitizer, and live table updates on the Grading Logs tab.
* **Bilingual Localization (English & Tagalog)**:
  * Full reactive `EN / TL` translation support across both the Flutter mobile app and Django web dashboard.
* **Regulatory Compliance & In-App Update Distribution**:
  * Full compliance with **Republic Act No. 10173** (Philippine Data Privacy Act of 2012) and EULA gating.
  * In-app update checker querying `https://niyosense.me/api/v1/system/app-version/` and direct installation flow via `https://niyosense.me/install/`.