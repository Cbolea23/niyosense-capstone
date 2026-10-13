# Project Name: NiyoSense
**Description**: Fully offline-first, multimodal coconut maturity grading system (Visual + Acoustic) for mobile devices, supported by a Django web dashboard for analytics and log synchronization.

---

## 1. System Architecture & Tech Stack
* **Mobile Frontend**: Flutter / Dart
  * Operates **100% offline-first**.
  * Local database: SQLite (`sqflite`).
  * On-device Machine Learning: TensorFlow Lite (`tflite_flutter`).
* **Backend Dashboard & Cloud API**: Django + Django REST Framework
  * Database: PostgreSQL (Neon DB).
  * Synchronization endpoint: Bulk log sync (`/api/v1/sync/bulk-logs/`).
* **Deployment & Containerization**:
  * Dockerized Django setup (volume-mounted media persistence to prevent file loss on container restarts).
  * Remote tunneling for multi-network sync via Cloudflare Tunnel (`cloudflared`).

---

## 2. Models & Preprocessing Pipeline
The system relies on two TFLite models expecting `[1, 3, 224, 224]` Float32 input tensors:
1. **Visual Model (`img_best.tflite`)**:
   * Evaluates coconut husk visual features.
   * Input: Camera frame normalized and resized to `[1, 3, 224, 224]` (NCHW format).
2. **Acoustic Model (`spec_best.tflite`)**:
   * Evaluates coconut acoustic resonance from a 4-second tapping audio file.
   * Audio recording specifications: 4.0 seconds, 22050 Hz sample rate, mono PCM (`.wav`).
   * On-device preprocessing (`SpectrogramService`):
     * FFT size (`n_fft`): 2048
     * Hop length: 512
     * Mel bands (`n_mels`): 128
     * Top-dB normalization range: -80 dB to 0 dB
     * Colormap: Matplotlib `magma` colormap
     * Resized to `[1, 3, 224, 224]` Float32 tensor.
3. **Late-Fusion Decision Logic**:
   * Weighted formula: `Final Probability = (0.60 * P_visual) + (0.40 * P_audio)`
   * Resolves maturity classification: `Buko / Malauhog` (or `Mature / Premature`).

---

## 3. Current Implementation Status & Solved Hurdles
* **Offline Audio Pipeline**:
  * Successfully implemented real-time audio recording (`.wav`) via `record` package at 22050 Hz for exactly 4 seconds.
  * Implemented pure-Dart FFT and Mel-spectrogram generation in `SpectrogramService.dart`.
  * Resolved `.reshape()` compilation issues by importing `package:tflite_flutter/tflite_flutter.dart`.
  * Verified end-to-end on-device execution: both `img_best.tflite` and `spec_best.tflite` run on the mobile device with genuine data, logging fused predictions to SQLite.
* **Web Dashboard & Backend**:
  * Removed "Offline-Ready" tags from `header.html` and `sidebar.html` (the web console is a reporting dashboard; offline capability is mobile-exclusive).
  * Fixed Chart.js canvas resizing issues and infinite redraw loops on the Analytics tab by constraining container heights (`h-72`) and triggering `resize()` on tab switch.
  * Resolved template tag errors by ensuring `{% load static %}` is placed in templates rendering assets.
  * Configured multi-network sync via `cloudflared` tunnel, `ALLOWED_HOSTS = ['*']`, `SECURE_PROXY_SSL_HEADER`, and `CSRF_TRUSTED_ORIGINS`.
* **Branding, UI & Cluster Sampling Notice**:
  * Integrated custom logo (`assets/logo/logo.png`) in the Django dashboard sidebar, browser favicon, and the Flutter `ScanResultScreen` / `HomeScreen`.
  * Implemented Cluster Maturity Baseline Notice Card (Option 1) in `ScanResultScreen` and cluster sampling badge in `VisualScanScreen`, guiding farmers/operators that 1 scanned nut serves as the base maturity stage for the entire cluster (bungkos).
* **Cross-Platform Localization (English & Tagalog)**:
  * Implemented reactive `AppTranslations` in Flutter across `HomeScreen`, `SettingsScreen`, `VisualScanScreen`, `AcousticScanScreen`, and `ScanResultScreen`.
  * Added in-app interactive language switcher (EN / TL) in mobile `SettingsScreen` and completed `data-i18n` binding across all web dashboard tabs and modals.
* **Production Docker Containerization & Media Persistence**:
  * Configured `backend/Dockerfile` (Python 3.12-slim, `libpq-dev`, `build-essential`, `iproute2`, Gunicorn).
  * Configured `backend/docker-compose.yml` with persistent volume mounts (`./media:/app/media` and `./static:/app/static`), automated migrations and `collectstatic`, and environment variable support for Neon PostgreSQL (`DATABASE_URL`).
  * Integrated `whitenoise` for zero-overhead static asset serving and configured Django `urls.py` for persistent media serving under standalone container execution.
  * Successfully verified remote multi-network mobile cellular data (4G/5G) sync through Cloudflare Quick Tunnel (`trycloudflare.com`) with automated image and 4-second `.wav` audio upload persistence.
  * Added dedicated `Unrecognized` stage handling across Django models, serializers, and web dashboard table badges to record and flag non-coconut / low-confidence scans.
  * Added "Install Mobile App (Android)" card in web dashboard Settings with direct APK download (`/media/downloads/niyosense.apk`) and dedicated scan-to-install QR code modal.
  * Implemented multi-operator individual login system (`maria_santos`, `juan_delacruz`, `pedro_reyes`, `aggregator1`) with client-side credential persistence in Flutter settings, enabling concurrent multi-phone field grading with distinct audit trails.

---

## 4. Immediate Next Steps / Pending Tasks
1. Conduct physical coconut grading field tests (comparing model classification accuracy on actual buko vs. malauhog nuts).
2. Deploy Docker container to production VPS / Render / Railway with attached persistent volume.