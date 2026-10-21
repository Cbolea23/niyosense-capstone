# 🥥 NiyoSense: Coconut Maturity Profiling & Grading System

[![Live Production](https://img.shields.io/badge/Production-Live-emerald?style=flat-square&logo=cloudflare)](https://niyosense.me)
[![Release](https://img.shields.io/badge/Release-v1.4.5%2B17-blue?style=flat-square&logo=android)](https://github.com/Cbolea23/niyosense-capstone/releases/tag/v1.4.5)
[![Framework](https://img.shields.io/badge/Mobile-Flutter%203.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Backend](https://img.shields.io/badge/Backend-Django%206.1-092E20?style=flat-square&logo=django)](https://djangoproject.com)
[![License](https://img.shields.io/badge/Compliance-RA%2010173%20%7C%20EULA-teal?style=flat-square)](https://niyosense.me/install/)

> **CCMS Capstone Project — Manuel S. Enverga University Foundation (MSEUF), Lucena City**  
> **Authors:** Christian Louis Bolea, Wayne Yzon Nagares, Seann Yves Saracho  
> **Adviser:** Engr. Roselyn A. Maaño  
> **Stakeholder:** Dr. Nona D. Nagares (Coconut Plantation Owner, Quezon Province)  

---

## 🌐 Live System Access

* **Official Production Web Dashboard:** [https://niyosense.me](https://niyosense.me)
* **Direct Mobile APK Download:** [Download NiyoSense v1.4.5 APK (100.25 MB)](https://github.com/Cbolea23/niyosense-capstone/releases/download/v1.4.5/niyosense.apk)
* **Mobile Onboarding Portal:** [https://niyosense.me/install/](https://niyosense.me/install/)
* **System Status & Uptime:** [https://niyosense.me/healthz](https://niyosense.me/healthz)

---

## 📌 Project Overview

**NiyoSense** is a dual-model audio-visual machine learning system designed to replace subjective manual tapping and visual inspection in post-harvest coconut sorting. Built for **Coconut Plantation Owners, Farm Managers, and Field Operators (*Mambubuko*)**, the system combines:

1. **An Offline-First Android Application:** Performs 100% on-device edge inference using TensorFlow Lite and client-side Fast Fourier Transform (FFT) signal processing without requiring cellular signal deep in coconut groves.
2. **A Centralized Cloud Web Dashboard:** Hosted on Render with Cloudflare SSL edge routing, providing real-time harvest inventory analytics, *bungkos* (cluster) volume tracking, estimated valuation, and commercial settlement reconciliation.

---

## 🏗️ System Architecture & Dual-Model AI Pipeline

```
                                  [ Cloudflare Edge CDN & DNS ]
                                                │
                                    (https://niyosense.me)
                                                │
                                                ▼
                                    [ Render Cloud Hosting ]
                             Dockerized Django 6.1 + Gunicorn WSGI
                                                │
                ┌───────────────────────────────┴───────────────────────────────┐
                ▼                                                               ▼
   [ Web Analytics Dashboard ]                                    [ Central REST API & Auth ]
  • Tailwind CSS & Chart.js                                      • Django REST Framework
  • Real-Time Delivery Summaries                                 • SimpleJWT Auth & Batch Sync
  • Dynamic QR Onboarding                                        • Render PostgreSQL + Cloudinary
                │                                                               ▲
                │                                                               │ (Batch Sync)
                ▼                                                               │
  [ GitHub Releases CDN ] ──────── (One-Tap APK Install) ──────► [ NiyoSense Android App ]
  • v1.4.5 Binary Storage                                        • Flutter 3.x / Dart
  • Global Edge Distribution                                     • On-Device TFLite Acoustic AI
                                                                 • Offline SQLite Engine
```

### Dual-Model Decision Pipeline
* **Model 1 — Visual Husk Model (`img_best_v2.tflite`):** Analyzes outer coconut husk coloration and texture (`[1, 320, 320, 3]` Float32).
* **Model 2 — Acoustic Spectrogram Model (`spec_best_v2.tflite`):** Analyzes resonance frequencies from a 4-second acoustic tapping recording converted into a 128-band Mel-spectrogram on-device.
* **Acoustic-Dominant 70/30 Decision Rule:**
  $$\text{Final Score} = (0.70 \times P_{\text{audio}}) + (0.30 \times P_{\text{visual}})$$
* **3-Gate Out-of-Distribution (OOD) Protection:** Rejects non-coconut objects (Gate 1), invalid tap-knock counts (Gate 2), and ambiguous confidence (Gate 3).

---

## 📚 Capstone Documentation Suite

| Document | Description |
| :--- | :--- |
| **[`NIYOSENSE_TECHSTACK_AND_VARIANCE_REPORT.md`](NIYOSENSE_TECHSTACK_AND_VARIANCE_REPORT.md)** | Full technical stack inventory, proposal-vs-implementation variance matrix, and ISO/IEC 25010 compliance. |
| **[`CAPSTONE_PAPER_REVISION_GUIDE.md`](CAPSTONE_PAPER_REVISION_GUIDE.md)** | Chapter-by-chapter manuscript alignment guide for proposal paper revisions. |
| **[`HOW_TO_TEST_AND_EXPLAIN_BUNGKOS.md`](HOW_TO_TEST_AND_EXPLAIN_BUNGKOS.md)** | Oral defense script and demonstration guide for *bungkos* (cluster) representative sampling. |
| **[`assets/models/TFLITE_INTEGRATION_GUIDE.md`](assets/models/TFLITE_INTEGRATION_GUIDE.md)** | Technical reference for on-device TFLite tensor specifications and audio DSP parameters. |
| **[`Context.md`](Context.md)** | Full system context and runtime reference for developers and reviewers. |

---

## 🚀 Local Development Setup

### 1. Web Dashboard & API (Django Backend)
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

# Run migrations and seed initial data
python manage.py migrate
python manage.py loaddata initial_data.json

# Start development server
python manage.py runserver 0.0.0.0:8000
```
Open [http://localhost:8000](http://localhost:8000) in your browser. Default admin login credentials: `bolea23` / `admin`.

### 2. Mobile Field Client (Flutter App)
```bash
# Ensure Flutter SDK ^3.8.1 is installed
flutter doctor

# Fetch dependencies
flutter pub get

# Run on connected Android device
flutter run --release
```

---

## ⚖️ Ethical & Legal Compliance

* **Republic Act No. 10173 (Philippine Data Privacy Act of 2012):** Built-in data minimization, operator consent management, and privacy notices.
* **End-User License Agreement (EULA):** Mandatory terms of usage embedded on `/install/` and on initial mobile app startup.
