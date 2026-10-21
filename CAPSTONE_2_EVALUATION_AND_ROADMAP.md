# NiyoSense: Capstone 2 Project Inspection & Evaluation Report

**Evaluation Status:** ✅ **100% OF ROADMAP MILESTONES IMPLEMENTED IN v1.4.5+17**  
**Date:** October 2026  
**Project:** NiyoSense: Web and Mobile Coconut Maturity Profiling and Grading System using Multimodal Audio-Visual Machine Learning for Small-Scale Coconut Aggregators  
**Live Production URL:** [https://niyosense.me](https://niyosense.me) | **Release:** [v1.4.5](https://github.com/Cbolea23/niyosense-capstone/releases/tag/v1.4.5)  
**Researchers:** Christian Louis Bolea, Wayne Yzon Nagares, Seann Yves Saracho  
**Institution:** College of Computing and Multimedia Studies, Manuel S. Enverga University Foundation, Lucena City  
**Target Beneficiaries:** Coconut Plantation Owners and On-Site Farm Managers in Quezon Province  

> **Implementation Note:** All recommendations outlined below (Delivery Batch sessions, payout pricing calculators, shareable vouchers, cluster bungkos sampling, ambient noise calibration, and cloud hosting alignment) were systematically implemented and released in build `v1.4.5+17`.

---

## 1. Executive Summary & Persona Perspective

### The Persona: Small-Scale Coconut Aggregator & Farm Owner
> *"I buy coconuts from local smallholders and farmers across Quezon Province. In every delivery or harvest pile (*salansan*), I handle between 300 to 2,000 coconuts a day. Time is money, trust with farmers is essential, and connectivity in the grove is near zero. If this app slows down my crew, we won't use it. If it gives me consistent, fast grading, protects me from paying top dollar for premature nuts, and gives me a clean receipt to show the farmer, it is an indispensable business tool."*

---

## 2. Review of the System Architecture & Current Implementation Status

Based on an inspection of the active codebase (`Context.md`, Flutter client, and Django backend):

### Where the Project Excels (Key Accomplishments)
1. **Genuine Offline-First Edge Inference:**
   * Unlike many capstones that claim "offline" but secretly require a server for API calls, NiyoSense executes `tflite_flutter` on-device with custom models (`img_best.tflite` for husk vision and `spec_best.tflite` for tapping resonance).
   * Audio Mel-spectrogram generation (`n_fft: 2048`, `n_mels: 128`, magma colormap) is performed directly in Dart (`SpectrogramService.dart`), making mobile scanning truly independent of farm cellular reception.
2. **Cluster Sampling Baseline Architecture:**
   * The team recognized that scanning every single nut is impractical in large piles. The implementation of the **Cluster Maturity Baseline Notice** (where one representative nut grades the bundle/*bungkos*) demonstrates deep domain understanding.
3. **Bi-Directional Localization (EN / TL):**
   * Incorporating Tagalog translations across screens reflects empathy for local agricultural workers.
4. **Robust Remote Sync Architecture:**
   * SQLite local logging syncs to Django/PostgreSQL via bulk endpoints with media preservation in Docker and Cloudflare tunnel routing.
5. **Multi-Operator Support:**
   * Added multi-user accounts so different sorters in the same cooperative or bodega can log under their own names.

---

## 3. Critical Real-World Gaps (Owner's Pain Points)

| # | Current Gap | Real-World Impact on Owner | Recommendation |
|---|---|---|---|
| **1** | **No Batch / Payout Calculation** | Scans are stored as raw counts. The buyer cannot see how much cash to disburse to the farmer per delivery. | Introduce a "Delivery Batch" session with customizable unit pricing per grade (e.g., Mature: ₱12, Premature: ₱7, Reject: ₱0). |
| **2** | **No Printable/Shareable Farmer Receipt** | Disagreements occur at settlement. The farmer wants proof of why 30 nuts were deducted as premature. | Provide an exportable Delivery Receipt (PDF, summary image, or SMS text) showing counts, percentages, and total payout. |
| **3** | **Environmental Noise Sensitivity** | Coconuts are sorted near roads, chainsaws, running trucks, and barking dogs. Background noise can contaminate the 4-second audio tap. | Implement a pre-scan ambient noise check threshold and peak transient auto-trimming for the tapping impact. |
| **4** | **Vercel vs. PyTorch/Librosa Discrepancy in Proposal** | The proposal manuscript mentions Vercel serverless for Django + ML backend, but Vercel limits serverless functions to 50–250MB, making PyTorch/Librosa hosting unfeasible. | Align the manuscript with your actual Dockerized VPS / Cloudflare / local deployment architecture. Emphasize that inference was shifted to on-device TFLite to guarantee 100% rural uptime. |

---

## 4. Proposed Feature Roadmap for Capstone 2 & Defense

### Priority 1: High-Impact / Feasible for Immediate Completion
1. **Batch Delivery & Settlement Voucher (Mobile & Web)**
   * Group individual scans under a **Batch ID** (e.g., `Batch-20261013-MangJuan`).
   * Include buying rates:
     * *Mature / Niyog* (₱/pc)
     * *Buko / Young* (₱/pc)
     * *Reject / Premature* (₱/pc or deduction)
   * Auto-generate a **Payout Summary** showing Total Harvest Count, Breakdown %, and Gross Amount Payable.
2. **One-Tap Shareable Summary (Voucher/Receipt)**
   * Generate an image or simple PDF receipt that can be shared via Bluetooth, Messenger, or printed via thermal printer for the farmer.
3. **Sample Audit Mode**
   * Give the aggregator two workflow options:
     * **Audit Mode (Recommended for large piles):** Scan 10–20 random sample nuts from a truckload of 500 to estimate the batch grade percentage.
     * **Piece-by-Piece Mode:** For high-value seedling or retail coconut inspection.

### Priority 2: Technical Polish for Manuscript & Defense
1. **Model Explainability & Confidence Thresholds:**
   * Highlight confidence scores below 65% with an amber warning: *"Mababang kumpiyansa: I-tap muli"* to prevent inaccurate automated logging.
2. **Ground Truth Validation Protocol (Section 5.4.1):**
   * Explicitly document the physical validation procedure (cracking open a percentage of scanned coconuts to measure meat thickness in millimeters and water volume) to substantiate the accuracy metrics in Chapter 5.
3. **Dataset Augmentation Documentation:**
   * Document audio pitch shifts, background farm noise injection, and visual brightness variations to justify model robustness beyond the initial 150/173 samples.

---

## 5. Summary Scorecard & Readiness Verdict

* **Concept & Problem Relevance:** **9.8 / 10** (Targets an urgent, unautomated agricultural challenge).
* **Technical Rigor & Innovation:** **9.5 / 10** (True multimodal on-device TFLite + Mel-spectrogram processing in Dart is outstanding for undergraduate IT).
* **Commercial / Field Usability:** **8.2 / 10** (Needs batching and pricing settlement features to be a full business solution).
* **Overall Capstone 2 Trajectory:** **Strong Candidate for Best Capstone / High Distinction**, provided the economic link (pricing/batch payouts) and field validation data are completed.
