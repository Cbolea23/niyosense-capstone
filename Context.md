# Project Name: NiyoSense (v1.4.5 — Build 17)

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
  * Database: Embedded SQLite with automated fixture seeding (`initial_data.json`) on container start (56 scans, user accounts `bolea23`, `farm_worker`), with production support for external PostgreSQL via `dj-database-url` and `psycopg2-binary`.
  * Authentication: 30-day multi-device JWT (`SIMPLE_JWT` with `BLACKLIST_AFTER_ROTATION = False`) for field operators, and session authentication for web managers.
  * Synchronization endpoint: Concurrent bulk log & media sync (`/api/v1/sync/bulk-logs/`) with 5-attempt atomic locking retry handlers.
* **Production Deployment & Cloud Infrastructure**:
  * **Render Web Services**: Containerized Docker image (`niyosense-capstone.onrender.com`) running Python 3.12, dynamic `$PORT` binding, and `/healthz` uptime health check.
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
3. **3-Gate Out-of-Distribution (OOD) Validation Pipeline (`ModelService.dart`)**:
   * **Gate 1 (Camera Pixel & Texture Gate on `64×64` RGB)**: Checks luminance exposure ($\mu \in [28, 242], \sigma \ge 8.0$), Center 60% ROI HSV green/olive/brown husk ratio ($\ge 40\%$), and Sobel gradient edge roughness ($\le 30.0$ to reject grass, foliage, and synthetic green bottles/objects).
   * **Gate 2 (Spectrogram Vertical Tap-Stripe Counter on `64×64` Grid)**: Inspects the upper 70% frequency rows for distinct vertical tap stripes (`colEnergy[x] > median + 35` and `> 85`, separated by $\ge 3$ columns), requiring strictly `2..5` knocks.
   * **Gate 3 (Softmax Temperature Scaling & Cross-Model Check)**: Applies temperature scaling ($T = 1.6$), caps display confidence at `96.5%`, requires final confidence $\ge 65.0\%$, and resolves cross-model disagreements when acoustic confidence is decisive ($\ge 75.0\%$).
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