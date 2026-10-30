# 🥥 NiyoSense: Web & Mobile Coconut Maturity Profiling and Valuation System

[![Live Production](https://img.shields.io/badge/Production-Live-emerald?style=flat-square&logo=cloudflare)](https://niyosense.me)
[![Release](https://img.shields.io/badge/Release-v1.5.2-blue?style=flat-square&logo=android)](https://github.com/Cbolea23/niyosense-capstone/releases/tag/v1.5.2)
[![Framework](https://img.shields.io/badge/Mobile-Flutter%203.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Backend](https://img.shields.io/badge/Backend-Django%206.1-092E20?style=flat-square&logo=django)](https://djangoproject.com)
[![Database](https://img.shields.io/badge/Database-PostgreSQL-336791?style=flat-square&logo=postgresql)](https://render.com)
[![Storage](https://img.shields.io/badge/Storage-Cloudinary%20CDN-3448C5?style=flat-square&logo=cloudinary)](https://cloudinary.com)
[![Developer Portfolio](https://img.shields.io/badge/Portfolio-bolealabs.site-8A2BE2?style=flat-square)](https://bolealabs.site)

> **A non-destructive, offline-first agricultural intelligence platform combining on-device computer vision and acoustic digital signal processing to objectively grade young green coconuts (*Malauhog* vs. *Buko*) and eliminate post-harvest commercial valuation leakage.**

---

## 🌐 Live System Links

* **Live Web Dashboard:** [https://niyosense.me](https://niyosense.me)
* **Direct Android APK Download:** [Download NiyoSense Field v1.5.2 APK](https://github.com/Cbolea23/niyosense-capstone/releases/download/v1.5.2/niyosense.apk)
* **Mobile Onboarding & EULA Portal:** [https://niyosense.me/install/](https://niyosense.me/install/)
* **Backend Health Check:** [https://niyosense.me/healthz](https://niyosense.me/healthz)

---

## 📌 Project Overview

In commercial coconut farming, post-harvest young green coconuts (*Cocos nucifera* L.) are traditionally graded using destructive splitting or subjective knuckle-tapping. Because immature green coconuts exhibit near-identical exterior hulls between the **Malauhog** (translucent jelly meat) and **Buko** (soft tender meat) stages, human sensory error leads to substantial crop volume loss, price disputes, and revenue leakage during wholesale batch transactions.

**NiyoSense** solves this with a two-tier ecosystem:

1. **`NiyoSense Field` (Offline-First Mobile App):**  
   Runs 100% locally on Android devices inside remote harvest sheds (*kamalig*). Utilizes an on-screen reticle guide, audio recording, in-memory **Short-Time Fourier Transform (STFT)** DSP spectrogram generation, and **Dual-Model YOLOv8 edge inference** via quantized 8-bit TensorFlow Lite—giving farm managers objective grading in under 1 second without internet connection.
2. **`NiyoSense Web Portal` (Executive Plantation Dashboard):**  
   A cloud platform built with Django REST Framework, Render Managed PostgreSQL, and Cloudflare Edge Security. Enables plantation owners to configure dynamic buying rates (₱/pc), monitor real-time cluster (*bungkos*) distribution, audit tamper-proof grading logs, and reconcile commercial batch payouts to prevent financial leakage.

---

## 🏗️ System Architecture

```
                                  [ Cloudflare Edge CDN & DNS ]
                                                │
                                    (https://niyosense.me)
                                                │
                                                ▼
                                    [ Render Cloud Web Host ]
                                Dockerized Django 6.1 + Gunicorn
                                                │
                 ┌──────────────────────────────┴──────────────────────────────┐
                 ▼                                                             ▼
    [ Executive Web Dashboard ]                                   [ Central REST API & Auth ]
   • Owner Passkey Authentication                                • SimpleJWT Mobile Session
   • Real-Time Harvest Metrics & KPIs                            • Atomic Bulk Log & Media Sync
   • Commercial Batch Settlement Engine                          • Render Managed PostgreSQL 16
   • Dynamic Ephemeral QR Session Pairing                        • Cloudinary CDN Media Storage
                 │                                                             ▲
                 │                                                             │ (Batch Sync via QR)
                 ▼                                                             │
   [ GitHub Releases CDN ] ────── (One-Tap APK Install) ───────► [ NiyoSense Field Client ]
   • v1.5.2 Binary Distribution                                  • Flutter 3.x / Dart 3.x
   • Global Edge Availability                                    • Dual-Model TFLite Edge AI
                                                                 • Pure-Dart Mel-Spectrogram DSP
                                                                 • Local SQLite ACID Cache
```

---

## 🧠 Multimodal AI & Decision Pipeline

Rather than relying on visual inspection alone, NiyoSense uses an **Acoustic-Dominant 70/30 Late Fusion Decision Rule**:

$$P_{\text{final}}(c) = (0.70 \times P_{\text{audio}}) + (0.30 \times P_{\text{visual}})$$

* **Visual Model (`img_best_v2.tflite`):** Quantized YOLOv8-cls neural network analyzing coconut exocarp surface texture and hue ($[1, 224, 224, 3]$ tensor).
* **Acoustic Model (`spec_best_v2.tflite`):** Quantized YOLOv8-cls neural network analyzing internal resonance from a 4.0-second knuckle-knock audio clip converted on-device into a 128-band Mel-spectrogram via STFT.
* **Why 70% Audio?** Internal endosperm meat density modulates acoustic shell resonance far more significantly than subtle exterior husk coloration.
* **Pre-Inference Sensor Guardrails:**
  * **Gate 1 (Visual):** HSV luminance and color distribution check to reject non-coconut objects.
  * **Gate 2 (Acoustic):** RMS energy and knock cadence validation (requires 2–4 distinct strikes).
  * **Gate 3 (Conflict Veto):** Automatically flags inconclusive scans if audio and visual models disagree by $>40\%$.

---

## 🛠️ Technology Stack

| Component | Framework / Technology | Purpose |
| :--- | :--- | :--- |
| **Mobile Frontend** | Flutter & Dart 3.x | Cross-platform mobile client with camera reticle and audio recording controllers |
| **Local Persistence** | SQLite 3 | Offline ACID-compliant field queuing for remote grove operations |
| **Edge AI Runtime** | TensorFlow Lite (`tflite_flutter`) | Quantized 8-bit on-device neural network execution on mobile CPU |
| **Digital Signal Processing** | Pure-Dart STFT & Mel-Spectrogram | In-memory audio-to-spectrogram image matrix generation |
| **Backend & Web** | Django 6.1 & Django REST Framework | Centralized REST APIs, QR pairing handshake, and administrative web portal |
| **Cloud Database** | PostgreSQL 16 (Render Managed) | Central repository for harvest manifests, device profiles, and settlement records |
| **Media Storage** | Cloudinary CDN | High-performance cloud media storage for verified audit photos and audio clips |
| **Edge Security & Routing** | Cloudflare Edge CDN & DNS | Full SSL/TLS encryption, reverse proxying, and custom domain routing |

---

## 🚀 Local Development Setup

### 1. Web Backend (Django)
```bash
# Navigate to backend directory
cd backend

# Create and activate virtual environment
python -m venv .venv
# Windows:
.venv\Scripts\activate
# Linux/macOS:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run migrations and start server
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```
* Access the web dashboard at `http://localhost:8000`.

### 2. Mobile Client (Flutter)
```bash
# Ensure Flutter SDK is installed
flutter doctor

# Fetch dependencies
flutter pub get

# Run on connected Android device
flutter run --release
```

---

## 👨‍💻 Developer & Authors

* **Lead Software Engineer & Architect:** Christian Louis Bolea — [bolealabs.site](https://bolealabs.site)
* **Machine Learning Engineer:** Wayne Yzon Nagares
* **Quality Assurance & Documentation:** Seann Yves Saracho

---

## ⚖️ License & Ethical Standards

* Developed in compliance with the **Philippine Data Privacy Act of 2012 (Republic Act No. 10173)**.
* End-User License Agreement (EULA) enforced on app initialization and downloadable at `https://niyosense.me/install/`.
