# 🥥 NiyoSense: Coconut Maturity Profiling & Grading System

[![Live Production](https://img.shields.io/badge/Production-Live-emerald?style=flat-square&logo=cloudflare)](https://niyosense.me)
[![Release](https://img.shields.io/badge/Release-v1.5.2-blue?style=flat-square&logo=android)](https://github.com/Cbolea23/niyosense-capstone/releases/tag/v1.5.2)
[![Framework](https://img.shields.io/badge/Mobile-Flutter%203.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Backend](https://img.shields.io/badge/Backend-Django%206.1-092E20?style=flat-square&logo=django)](https://djangoproject.com)
[![Database](https://img.shields.io/badge/Database-PostgreSQL-336791?style=flat-square&logo=postgresql)](https://render.com)
[![Storage](https://img.shields.io/badge/Storage-Cloudinary%20CDN-3448C5?style=flat-square&logo=cloudinary)](https://cloudinary.com)
[![Compliance](https://img.shields.io/badge/Compliance-RA%2010173%20%7C%20EULA-teal?style=flat-square)](https://niyosense.me/install/)

> **CCMS Capstone Project — Manuel S. Enverga University Foundation (MSEUF), Lucena City**  
> **Authors:** Christian Louis Bolea, Wayne Yzon Nagares, Seann Yves Saracho  
> **Adviser:** Engr. Roselyn A. Maaño | **Technical Mentor / Panelist:** Prof. Eleazar Salanda  
> **Stakeholder:** Dr. Nona D. Nagares (Coconut Plantation Owner, Quezon Province)  

---

## 🌐 Live System Access

* **Official Production Web Portal:** [https://niyosense.me](https://niyosense.me) *(Protected by Master Security Passkey — Default: `niyosense2026`)*
* **Direct Mobile APK Download:** [Download NiyoSense v1.5.2 APK (101.4 MB)](https://github.com/Cbolea23/niyosense-capstone/releases/download/v1.5.2/niyosense.apk)
* **Mobile Onboarding & EULA Portal:** [https://niyosense.me/install/](https://niyosense.me/install/)
* **System Status & Uptime Health Check:** [https://niyosense.me/healthz](https://niyosense.me/healthz)

---

## 📌 Project Overview

**NiyoSense** is a dual-model audio-visual machine learning system designed to replace subjective manual tapping and visual inspection in post-harvest coconut sorting. Built for **Coconut Plantation Owners** and **On-Site Farm Managers**, the system combines:

1. **An Offline-First Android Application (`NiyoSense Field` v1.5.1):** Operates 100% on-device at the plantation grading station using two independent TensorFlow Lite convolutional neural networks and an in-memory pure-Dart Mel-spectrogram signal processor, eliminating reliance on cellular reception in rural groves.
2. **A Centralized Cloud Web Dashboard (`https://niyosense.me`):** Deployed on Render with Cloudflare SSL edge routing, persistent Render Managed PostgreSQL, and Cloudinary CDN storage. Protected by a **Master Security Passkey Gate**, providing plantation owners with real-time cluster (*bungkos*) volume analytics, estimated crop valuation, and a **Commercial Settlement & Revenue Leakage Calculator** ($\Delta V = V_{\text{est}} - V_{\text{actual}}$).

---

## 🏗️ System Architecture & Dual-Model AI Pipeline

```
                                  [ Cloudflare Edge CDN & DNS ]
                                                │
                                    (https://niyosense.me)
                                                │
                                                ▼
                                    [ Render Cloud Hosting ]
                              Dockerized Django 6.1 + Gunicorn
                                                │
                 ┌──────────────────────────────┴──────────────────────────────┐
                 ▼                                                             ▼
    [ Web Analytics Portal ]                                      [ Central REST API & Auth ]
   • Protected by Master Passkey                                 • SimpleJWT Mobile Auth
   • Real-Time Cluster (Bungkos) KPIs                            • Atomic Bulk Log & Audio Sync
   • Settlement & Revenue Leakage Engine                         • Render Managed PostgreSQL
   • Dynamic Station QR Onboarding                               • Cloudinary CDN Media Storage
                 │                                                             ▲
                 │                                                             │ (Batch Sync)
                 ▼                                                             │
   [ GitHub Releases CDN ] ────── (One-Tap APK Install) ───────► [ NiyoSense Android App ]
   • v1.5.2 Binary Storage                                       • Flutter 3.x / Dart SDK
   • Global Edge Distribution                                    • On-Device TFLite Edge AI
                                                                 • Pure-Dart Mel DSP Engine
                                                                 • Offline SQLite Local Cache
```

### Dual-Model Decision Pipeline
* **Model 1 — Visual Husk Model (`img_best_v2.tflite`):** Standalone `YOLOv8-cls` neural network analyzing outer coconut husk coloration and texture (`[1, 320, 320, 3]` Float32).
* **Model 2 — Acoustic Spectrogram Model (`spec_best_v2.tflite`):** Standalone `YOLOv8-cls` neural network analyzing internal resonance from a standardized 4.0-second tapping recording (`22,050 Hz` 16-bit PCM `.wav`) converted into a 128-band Slaney Mel-spectrogram on-device.
* **Acoustic-Dominant 70/30 Decision Rule:**
  $$P_{\text{final}}(c) = (0.70 \times P_{\text{audio}}) + (0.30 \times P_{\text{visual}})$$
  *Outer green husks of Buko and Malauhog appear near-identical, but internal endosperm meat thickness strongly modulates acoustic knock resonance.*
* **3-Gate Out-of-Distribution (OOD) Protection:**
  * **Gate 1 (Controlled Station Visual Gate):** HSV chromaticity window ($H \in [36^\circ, 148^\circ]$), core foreign color rejection, 3D spherical shading check, and Sobel texture roughness filter.
  * **Gate 2 (Acoustic Signal Processing & SOP):** First-order 300 Hz High-Pass Filter and standardized 3-knock cadence at 5–10 cm microphone distance.
  * **Gate 3 (Temperature Scaling & Late Fusion):** Softmax temperature scaling ($T = 1.6$, 96.5% confidence cap) combined via 70/30 weighting.

---

## 👥 Target Beneficiaries & Role-Based Access Control

| Role | Interface | Access Control | Primary Responsibilities |
| :--- | :--- | :--- | :--- |
| **Plantation Owner** | Central Web Dashboard (`https://niyosense.me`) | Master Security Passkey (Configurable, default `niyosense2026`) | Oversees plantation-wide harvest volume by *bungkos* (clusters), tracks **Estimated Crop Valuation**, audits commercial buyer settlements using the **Revenue Leakage Calculator** ($\Delta V = V_{\text{est}} - V_{\text{actual}}$), manages field manager accounts, and configures buying rates (₱/nut). |
| **On-Site Farm Manager** | Mobile App (`NiyoSense Field` v1.5.1 on Android) | On-site Operator Account (Offline-First + JWT Cloud Sync) | Conducts visual-acoustic grading at the **Controlled Grading Station**, inputs **Bungkos Coconut Counts (`bunch_count`)**, manages **Harvest Delivery Batches**, prints/shares digital harvest vouchers, and syncs field logs. |

---

## 📚 Capstone Documentation Suite

| Document | Description |
| :--- | :--- |
| **[`NIYOSENSE_CAPSTONE_MANUSCRIPT.md`](NIYOSENSE_CAPSTONE_MANUSCRIPT.md)** | **Complete, publication-ready Capstone Manuscript (Chapters 1–6)** with full literature review, theoretical frameworks, DSP mathematical formulas, experimental results (**92.8% Fused Accuracy**), and ISO/IEC 25010 evaluation (**4.84 / 5.00**). |
| **[`CAPSTONE_PAPER_REVISION_GUIDE.md`](CAPSTONE_PAPER_REVISION_GUIDE.md)** | Chapter-by-chapter manuscript alignment guide for the documentation team. |
| **[`NIYOSENSE_TECHSTACK_AND_VARIANCE_REPORT.md`](NIYOSENSE_TECHSTACK_AND_VARIANCE_REPORT.md)** | Full technical stack inventory, proposal-vs-implementation variance matrix, and ISO/IEC 25010 compliance. |
| **[`HOW_TO_TEST_AND_EXPLAIN_BUNGKOS.md`](HOW_TO_TEST_AND_EXPLAIN_BUNGKOS.md)** | Oral defense narrative and demonstration script for cluster (*bungkos*) representative sampling. |
| **[`assets/models/TFLITE_INTEGRATION_GUIDE.md`](assets/models/TFLITE_INTEGRATION_GUIDE.md)** | Technical reference for on-device TFLite tensor specifications and audio DSP parameters. |
| **[`Context.md`](Context.md)** | Complete technical system architecture, data models, and developer reference. |

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

# Run migrations and apply fixtures
python manage.py migrate
python manage.py loaddata initial_data.json

# Start development server
python manage.py runserver 0.0.0.0:8000
```
Open [http://localhost:8000](http://localhost:8000) in your browser.  
* **Dashboard Access:** Enter the Master Passkey (`niyosense2026`).  
* **Django Admin:** [http://localhost:8000/admin/](http://localhost:8000/admin/) (Default: `bolea23` / `admin`).

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

* **Republic Act No. 10173 (Philippine Data Privacy Act of 2012):** Built-in data minimization, encrypted credentials, master passkey isolation for plantation financials, and statutory privacy notices.
* **End-User License Agreement (EULA):** Mandatory terms of usage embedded on [`https://niyosense.me/install/`](https://niyosense.me/install/) and on initial mobile app launch.
