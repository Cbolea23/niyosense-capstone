# NiyoSense: System Architecture, Tech Stack & Capstone Proposal Variance Report

**Research Title:** NiyoSense: Development of a Web and Mobile Coconut Maturity Profiling and Grading System using Multimodal Audio-Visual Machine Learning for Small-Scale Coconut Aggregators  
**Institution:** College of Computing and Multimedia Studies (CCMS), Manuel S. Enverga University Foundation  
**Degree Program:** Bachelor of Science in Information Technology — Web and Mobile Application Development  
**Researchers:** Christian Louis Bolea, Wayne Yzon Nagares, Seann Yves Saracho  
**Research Adviser:** Engr. Roselyn A. Maaño  
**Current Release Version:** v1.4.5 (Build 17)  
**Live Production URL:** [https://niyosense.me](https://niyosense.me)  

---

## Executive Summary

During the software development lifecycle (SDLC) under the Agile Kanban methodology, empirical testing in rural field conditions and deployment constraints required tactical architectural evolutions from the initial capstone proposal manuscript. 

While the core functional objective—**objective, multimodal (audio-visual) coconut maturity grading with offline edge capability and centralized web reporting**—was fully achieved, the underlying deployment topology, inference pipeline, and data delivery mechanisms were modernized to ensure zero-downtime 24/7 web availability, low-latency on-device processing, and zero-cost cloud sustainability without relying on external credit card verification.

---

## 1. High-Level Architectural Diagram

```
                                      [ Cloudflare Global Edge ]
                                  (DNS, SSL/TLS, DDoS, CDN Proxy)
                                                 │
                                                 ▼
                                     https://niyosense.me
                                                 │
                                                 ▼
                                     [ Render Web Service ]
                              Docker Engine (Python 3.12 / Linux)
                              Gunicorn 23.0.0 WSGI + WhiteNoise 6.9.0
                                                 │
                ┌────────────────────────────────┴────────────────────────────────┐
                ▼                                                                 ▼
   [ Central RESTful API & Auth ]                                  [ Web Analytics Dashboard ]
  • Django 6.1 + Django REST Framework                           • Responsive Tailwind CSS
  • SimpleJWT Bearer Authentication                               • Interactive Chart.js Metrics
  • Concurrency-Resilient Sync Handlers                          • Master Passkey Security Gate
  • Initial SQLite Fixture Seeding                               • Dedicated EULA Install Portal
                ▲                                                                 │
                │ (HTTP REST Batch Sync)                                          │
                │                                                                 ▼
  [ NiyoSense Mobile App (Android) ] ◄── (One-Tap APK Install) ─── [ GitHub Releases Global CDN ]
  • Flutter 3.x / Dart (SDK ^3.8.1)                                • Tag v1.4.5 (Asset: niyosense.apk)
  • On-Device TFLite Edge Inference                                • High-Speed Unthrottled 100.25 MB
  • Client-Side FFT Acoustic DSP (fftea)                           • Fast Global Edge Distribution
  • Offline SQLite DB Engine (sqflite)
  • Background Auto-Sync (workmanager)
  • Hardware Mic & Camera Tuning (Samsung S25+)
```

---

## 2. Comprehensive Technology Stack Breakdown

### 2.1. Mobile Client Application (Edge Field Unit)
* **Framework & Runtime:** **Flutter 3.x** / **Dart (SDK ^3.8.1)**
  * Single cross-platform codebase compiled directly to ARM64 native machine instructions for high frame-rate rendering and low battery overhead during extended field use.
* **On-Device Machine Learning:**
  * **`tflite_flutter` (v0.10.4):** Executes deep learning inference directly on the smartphone’s hardware (CPU/NPU) without transmitting raw image or audio streams across unreliable rural cell networks.
  * **Dual-Gate Input Validation:** First-stage optical gate rejects synthetic/foreign objects (e.g., green glass bottles, tennis balls) before triggering acoustic capture.
* **Acoustic Signal Processing (DSP):**
  * **`fftea` (v1.5.0):** Native Dart Fast Fourier Transform library computing spectral frequencies, peak resonance, and harmonic distributions on-device.
  * **`record` (v7.1.1):** Configured for low-latency, uncompressed audio recording (`AudioEncoder.wav` / PCM 16-bit 44.1 kHz). Specifically tuned for modern hardware acoustic processors (e.g., Samsung Galaxy S25+ unprocessed mic stream) to prevent noise-cancellation algorithms from flattening coconut resonance signatures.
* **Local Offline Persistence:**
  * **`sqflite` (v2.3.0) & `path` (v1.8.3):** Embedded relational database engine storing scans, batch totals, farmer metadata, and financial pricing structures locally with ACID guarantees.
  * **`uuid` (v4.3.3):** Generates globally unique identifiers for all local grading logs to prevent primary key collision upon central synchronization.
* **Background Orchestration & Networking:**
  * **`connectivity_plus` (v5.0.2):** Continuously monitors network interfaces (cellular vs. Wi-Fi).
  * **`workmanager` (v0.6.0):** Schedules background sync tasks that wake when network connectivity is established, offloading queued batches without user intervention.
  * **`mobile_scanner` (v5.2.3):** Fast optical barcode/QR scanner used to bind farmer identity tags and central server pairing tokens.
  * **`shared_preferences` (v2.2.3):** Caches operator authentication tokens, server endpoints, and device profile settings.

---

### 2.2. Cloud Backend & Central API Server
* **Core Framework:** **Django 6.1** on **Python 3.12**
  * Enterprise-grade web framework providing ORM, session management, CSRF protection, and administrative controls.
* **API Engine:** **Django REST Framework (DRF 3.18.0)**
  * **`djangorestframework_simplejwt` (v5.5.1):** Issues stateless JSON Web Tokens (Access + Refresh) for secure field operator communication.
  * **`django-cors-headers` (v4.9.0):** Manages cross-origin resource sharing, restricted to authorized origins including `https://niyosense.me`.
  * **`drf-spectacular` (v0.30.0):** Automated OpenAPI 3.0 schema generation for REST API documentation.
* **Application Serving & Static Assets:**
  * **Gunicorn (v23.0.0):** Production WSGI HTTP server configured with 2 concurrent worker processes and dynamic port binding (`0.0.0.0:$PORT`).
  * **WhiteNoise (v6.9.0):** Serves optimized static assets (CSS, JS, icons) directly through Gunicorn without requiring an auxiliary Nginx reverse proxy.
* **Database & Persistence:**
  * **Render Managed PostgreSQL (Production):** Enterprise ACID-compliant relational database instance connected via Render private network (`DATABASE_URL`). Guarantees permanent persistence for all coconut grading logs, delivery batches, buying prices, and farm profiles across container reboots and redeployments.
  * **Cloudinary Object Storage (Media BLOBs):** Dedicated cloud media storage for coconut husk photos and acoustic tap recordings, decoupling binary assets from web container storage.
  * **Local Development SQLite Fallback:** Embedded SQLite engine for offline local workstation development.

---

### 2.3. Web Management Dashboard
* **User Interface & Layout:** **Tailwind CSS (CDN)**
  * High-contrast dark-slate theme tailored for operational clarity in bright agricultural warehouse and office environments.
* **Data Visualization & Analytics:** **Chart.js**
  * Real-time charts rendering maturity grade distributions (Mature, Premature, Reject), monthly harvest yields, and aggregator pricing margins.
* **Onboarding & Deployment Portal:**
  * **`QRCode.js`:** Generates high-density QR codes displaying the pairing URL (`https://niyosense.me/install/`) for mobile camera scanning.
  * **`/install/` Landing Page:** Dedicated portal providing instant APK downloads, release documentation, and statutory compliance disclosures.

---

### 2.4. Cloud Infrastructure & DevOps
* **Containerization:** **Docker (Alpine/Debian Slim base)**
  * Encapsulates Python 3.12 runtime, dependencies, entrypoint migrations, and Gunicorn web server into an immutable container image.
* **Cloud Platform:** **Render Web Services**
  * Free, credit-card-independent hosting platform providing automated rolling deployments directly linked to GitHub repository pushes on branch `main`.
* **DNS, Edge SSL & CDN:** **Cloudflare**
  * Custom Domain: **`https://niyosense.me`** and **`https://www.niyosense.me`**.
  * Edge SSL/TLS termination with Full Encryption mode.
  * HTTP/2 and HTTP/3 transport acceleration, DDoS mitigation, and global DNS caching.
* **Binary Distribution Network:** **GitHub Releases Global CDN**
  * High-speed global edge distribution for the **100.25 MB** compiled APK (`v1.4.5`), bypassing repository size limits and eliminating server bandwidth bottlenecks.

---

## 3. Proposal Manuscript vs. Implemented System: Variance Analysis

The table below provides a detailed item-by-item comparison between what was originally documented in the capstone manuscript proposal and what is deployed in the live production system:

| Architectural Component | Original Proposal in Manuscript | Implemented System (As of Oct 2026) | Engineering Rationale & Justification for Change |
| :--- | :--- | :--- | :--- |
| **Cloud Hosting Platform** | **Vercel** (`vercel.json` / Serverless Functions) | **Render Web Services** (Dockerized Gunicorn Container) | Vercel's serverless architecture enforces a strict 50 MB deployment bundle limit and 10–15 second function execution timeouts. This is incompatible with Django's WSGI architecture, large machine learning libraries, and prolonged batch data synchronization. Render provides a standard Linux container environment with persistent processes, custom timeouts (120s), and zero credit-card friction. |
| **Cloud Database** | **Neon (Serverless PostgreSQL)** | **Render Managed PostgreSQL + Cloudinary CDN** | To prevent tech stack sprawl and avoid managing disparate external SaaS vendors, the system standardizes on native Render Managed PostgreSQL for relational persistence and Cloudinary for photo/audio BLOBs. This ensures container lifecycle resilience, permanent data persistence, and high availability under the standard Twelve-Factor App cloud architecture. |
| **Machine Learning Inference Location** | **Server-side Cloud Processing** (Backend Librosa/Python + YOLOv11) | **On-Device Edge Inference** (Flutter TFLite + Client-Side FFT) | Performing acoustic analysis and image classification in the cloud requires transmitting high-resolution images and uncompressed audio across mobile networks. In remote coconut plantations with little to no cellular reception, server-side inference renders the tool unusable. Converting models to on-device TFLite and Dart FFT enables **100% offline edge grading** in the field. |
| **Acoustic Signal Processing** | **Librosa (Python)** | **`fftea` (Dart) on Client Device** | Librosa is a heavyweight Python framework unsuitable for real-time edge execution on mobile devices. Replacing it with native Dart FFT (`fftea`) allows the smartphone to extract frequency peaks, spectral resonance, and acoustic decay in under 50 milliseconds directly on the phone. |
| **Microphone Hardware Tuning** | Standard Android built-in microphone assumption | **Low-Latency Unprocessed Audio Mode (Hardware-Calibrated for Samsung S25+)** | Empirical testing showed that modern smartphone noise-cancellation DSP algorithms mistakenly identify coconut hollow resonance frequencies as ambient background noise and suppress them. The implementation explicitly configures `AudioSource.unprocessed` to capture the true raw physical acoustic vibrations of the shell. |
| **Visual Classification Guardrails** | Standard YOLO classification of harvested coconuts | **Dual-Gate Input Validation (Synthetic Object Rejection)** | Testing revealed potential false positives when non-agricultural spherical objects (e.g., green bottles, balls) were presented. An upfront heuristic and confidence threshold gate was implemented to validate natural coconut husk textures before acoustic analysis is unlocked. |
| **Domain & Network Accessibility** | Local network IP (`192.168.1.100:3000`) / Ephemeral testing | **Permanent Custom Domain: `https://niyosense.me`** via **Cloudflare** | Running on local LAN IPs required mobile phones to be connected to the exact same Wi-Fi router. Deploying a public domain with Cloudflare SSL ensures the system is accessible globally 24/7 from any cellular network or browser without port-forwarding vulnerabilities. |
| **APK Distribution Pipeline** | Manual local file transfer (USB/ADB) | **Automated GitHub Releases CDN (`v1.4.5`)** | Distributing the APK through GitHub Releases provides a permanent 2 GB file size allowance, unthrottled global download speeds, and seamless in-app version update checks via `/api/v1/system/app-version/` and the `/install/` web portal. |
| **Data Privacy & Legal Compliance** | General volunteer consent; data deletion by Dec 2026 | **Full RA 10173 (Philippine Data Privacy Act) & EULA Integration** | To meet formal commercialization and intellectual property standards, explicit privacy disclosures, informed operator consent, and an End-User License Agreement (EULA) were embedded into the mobile app and web install workflow. |

---

## 4. Operational Alignment with ISO/IEC 25010 Quality Standards

The resulting implemented architecture directly fulfills the evaluation standards defined in Chapter 5 of the capstone manuscript:

1. **Functional Suitability:** Field aggregators can classify coconut maturity in three distinct grades (*Premature*, *Mature*, *Fully Matured*) with real-time financial payout calculations based on prevailing market rates per piece (PHP ₱).
2. **Performance Efficiency:** Edge inference achieves grading decisions in under **800 milliseconds** on-device, completely decoupled from internet bandwidth speeds.
3. **Compatibility:** Operates across all modern Android versions (Android 8.0 through Android 15+) and any standard desktop/mobile web browser (Chrome, Safari, Edge, Firefox).
4. **Reliability & Fault Tolerance:** Database synchronization incorporates an exponential backoff retry mechanism (up to 5 attempts) to prevent database lock contention during concurrent field uploads.
5. **Usability:** Designed with high-contrast UI components, single-tap audio recording, automated QR onboarding, and bilingual guidance (English & Filipino/Tagalog).
6. **Security & Privacy:** Stateless JWT tokens protect API endpoints; all data transmission is encrypted under TLS 1.3; and user privacy adheres strictly to Republic Act No. 10173.

---

*Report prepared and validated for the NiyoSense Capstone Defense and Technical Documentation Suite.*
