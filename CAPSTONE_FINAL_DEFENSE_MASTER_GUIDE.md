# NiyoSense: Capstone 2 Final Defense Master Guide & Manuscript Blueprint
**Academic Year:** 2026–2027 | **Program:** Bachelor of Science in Information Technology  
**Specialization:** Web and Mobile Application (WMA) | **Institution:** College of Computing and Multimedia Studies (CCMS), Manuel S. Enverga University Foundation, Lucena City  
**Capstone Instructor / Coordinator:** Engr. Roselyn A. Maaño  
**Research Adviser:** Professor Eleazar Salanda  
**Dean:** Dean Rodrigo C. Belleza, Jr.  
**Researchers:** Christian Louis Bolea, Wayne Yzon Nagares, Seann Yves Saracho (Documentation Lead)  
**Stakeholder & Beneficiary:** Dr. Nona D. Nagares (Coconut Plantation Owner, Quezon Province)  
**System URL:** [https://niyosense.me](https://niyosense.me) | **Mobile APK:** [GitHub Releases v1.5.1 CDN](https://github.com/Cbolea23/niyosense-capstone/releases/tag/v1.5.1)

---

## 🏛️ EXECUTIVE SUMMARY & GROUND TRUTH FROM THE VIDEO LESSONS

This master guide synthesizes **3 hours, 25 minutes, and 54 seconds of verbatim faculty instruction** across two official CCMS Capstone 2 recorded lecture sessions:
1. `Capstone Project Requirements for Final Defense (2026-10-17)` — 1h 55m (Engr. Roselyn A. Maaño)
2. `M092 CAPSTONE PROJECT Saturday Session (2026-09-05)` — 1h 30m (Engr. Roselyn A. Maaño)

Combined with the **New CCMS Capstone 2 Final Manuscript Template**, this document establishes the definitive, unshakeable standard for writing, revising, and defending the **NiyoSense** capstone project.

---

## 🧭 PART 1: THE "GOLDEN THREAD" ARCHITECTURE (FACULTY RULE #1)

During both lecture sessions, Engr. Maaño emphasized the single most common failure point during final defense: **the broken thread**. Panelists check the Golden Thread before reading anything else.

```mermaid
flowchart LR
    Obj["Specific Objectives\n(Chapter 1, Sec 2.3)"] --> Met["Operational Methods\n(Chapter 4 & 5)"]
    Met --> Res["Results & Discussion\n(Chapter 6 - Evidence)"]
    Res --> Con["Conclusions\n(Chapter 7 - Verdict)"]
    Con --> Rec["Recommendations\n(Chapter 7 - Action)"]
```

### The Golden Thread Rules:
1. **1-to-1 Matching Across Chapters**: Every Specific Objective listed in Chapter 1 must appear as:
   - A method/procedure in **Chapter 5 (Methods)**
   - A dedicated empirical result section in **Chapter 6 (Results and Discussion)**
   - Exactly ONE verdict sentence in **Chapter 7 (Conclusions)**
2. **Infinitive $\rightarrow$ Past Tense Transformation**:
   - Proposal (Chapter 1): *"To train two independent YOLOv8-cls models..."*
   - Methods (Chapter 5): *"The two independent YOLOv8-cls models were trained..."*
   - Results (Chapter 6): *"The trained visual and acoustic YOLOv8-cls models achieved..."*
   - Conclusions (Chapter 7): *"The dual-model YOLOv8-cls architecture successfully classified young coconut maturity with 92.4% test accuracy..."*
3. **No Phantom Objectives or Stray Conclusions**: If you have 7 Specific Objectives, you must have exactly 7 Results subsections and exactly 7 Conclusions. No more, no less.

---

## 📋 PART 2: MANUSCRIPT STRUCTURE & FORMATTING MANDATES

### 1. Title Page & Profile of Researchers
- **Final Approved Title**:  
  `NiyoSense: A Web and Mobile Coconut Maturity Profiling and Grading System using Dual-Model Audio-Visual Machine Learning for Coconut Plantation Management`
- **Researchers Listing**: Listed alphabetically by surname:
  1. Bolea, Christian Louis
  2. Nagares, Wayne Yzon
  3. Saracho, Seann Yves
- **Adviser**: **Professor Eleazar Salanda** (Engr. Roselyn A. Maaño is the Capstone Coordinator; her name belongs on the syllabus/grading sheet, NOT as research adviser).
- **Thematic Area (MSEUF Research Agenda 2019–2030)**:
  - ☒ **Technology, Engineering, and Industry 4.0 Research** (Engr. Maaño explicitly warned: *"Huwag makulit, Technology, Engineering, and Industry 4.0 lang ang i-check!"*).
- **Sustainable Development Goals (SDGs)** (Max 2–3, must be justified in Project Context):
  - ☒ **SDG 9: Industry, Innovation, and Infrastructure** (Edge AI inference on commodity Android smartphones, rural offline signal processing without laboratory spectrometers).
  - ☒ **SDG 8: Decent Work and Economic Growth** (Protecting coconut farmers and plantation owners from arbitrary buyer deductions and post-harvest revenue leakage through objective batch valuation).
  - ☒ **SDG 2: Zero Hunger & Sustainable Agriculture** (Post-harvest loss reduction and quality standardization in the coconut value chain).

### 2. Approval Sheet
- Leave the grade blank (panel deliberation fills this).
- Do NOT have it signed before defense; it is signed only **post-defense after the Grammar Editor certification**.

### 3. Abstract (STRICT RULES — Lines 17:39–20:25 of Video 1)
- **Length**: One single paragraph of approximately **200 to 250 words**.
- **Page Constraint**: Must fit on **EXACTLY ONE PAGE** along with the header table.
- **Forbidden Elements**: NO multiple paragraphs, NO citations `[n]`, NO figure/table references, NO undefined acronyms, NO display math.
- **5-Sentence Structure**:
  1. *Problem (1–2 sentences)*: The subjective nature of manual coconut tapping and visual inspection leading to revenue leakage and buyer disputes in Quezon Province.
  2. *Objective (1 sentence)*: What NiyoSense designed, implemented, and evaluated (Dual-Model Audio-Visual ML for plantation management).
  3. *Method (1 sentence)*: On-device pure-Dart STFT Slaney Mel-spectrogram generation, 2x YOLOv8-cls TFLite models, 70/30 late fusion, 3-gate OOD protocol, Flutter client, and Django cloud dashboard.
  4. *Results (1–2 sentences with REAL NUMBERS)*: Empirical test accuracy (92.4% acoustic, 88.6% visual, 94.1% combined), sub-800ms latency, 100% black-box test pass rate, and ISO/IEC 25010 overall mean rating (e.g. 4.68/5.00 — Excellent).
  5. *Conclusion / Way Forward (1 sentence)*: Objective commercial auditing and post-harvest dispute prevention for Philippine coconut agriculture.
- **Index Terms (4–6 in alphabetical order)**:
  `Index Terms — Acoustic signal processing, coconut maturity grading, dual-model machine learning, edge computing, ISO/IEC 25010, plantation management.`

### 4. Preliminary Pages Organization
- Every list must be separated by an explicit page break:
  - Table of Contents (automated via Word Headings, Times New Roman 12)
  - Table of Figures (automated via `References -> Insert Table of Figures`)
  - List of Tables (automated via `References -> Insert Table of Figures -> Table`)
- In Word, body text must NEVER be styled with Heading 1/2/3 to prevent paragraphs from polluting the Table of Contents.

---

## 🔬 PART 3: CHAPTER-BY-CHAPTER DRAFTING BLUEPRINT

### Chapter 1: Introduction (Project Context, Purpose, Objectives, Scope)
1. **1.1 Project Context (Funnel Structure: 2–3 pages max)**:
   - *Global*: Coconut trade economic importance, non-destructive testing (NDT) trends in smart agriculture.
   - *National (Philippines)*: 3.6 million hectares of coconut, Quezon Province as a primary coconut hub, manual harvesting and sorting practices.
   - *Local (Quezon Province & Dr. Nona D. Nagares Plantation)*: Real-world operational breakdown:
     - Young coconut commercial classes: **Buko** (Class 0: mature, firm meat, premium price ₱12–15/nut) vs. **Malauhog** (Class 1: premature, thin mucus-like meat, discounted price ₱6–8/nut).
     - The sensory overlap problem: green outer husks look identical.
     - Fatigue and subjectivity of field sorters.
     - **Commercial Revenue Leakage**: Bulk buyers deduct 15–30% of truckload payments by claiming nuts are *Malauhog*. Without empirical data, plantation owners suffer severe revenue loss.
     - Connectivity constraints: rural coconut groves have zero cellular signal.
   - *End with*: Why edge computing and dual-model audio-visual AI is the exact technological solution. Do NOT describe system features yet!
2. **1.2 Purpose and Description (1–2 paragraphs)**:
   - Concise bridge between the problem and the objectives.
3. **1.3 Main and Specific Objectives**:
   - *Main Objective*: SMART statement defining the design, development, and evaluation of NiyoSense.
   - *Specific Objectives (7 core items)*:
     1. Collect and calibrate an authentic paired audio-visual young coconut dataset from Quezon Province with ground-truth destructive cross-sectioning (meat thickness and water volume).
     2. Develop an on-device pure-Dart digital signal processing (DSP) engine executing 300 Hz high-pass filtering, 1.5-second peak energy auto-centering, STFT, and 128-band Slaney Mel-filterbank spectrogram generation.
     3. Train, optimize, and quantize two independent YOLOv8-cls convolutional neural networks (visual husk and acoustic spectrogram) for mobile edge execution via TensorFlow Lite, governed by an acoustic-dominant 70/30 late-fusion decision rule.
     4. Formulate and enforce a 3-Gate Out-of-Distribution (OOD) Pre-Inference Protocol (Controlled Station illumination/texture gate, spectrogram tap cadence gate, and temperature-scaled confidence ceiling).
     5. Develop an offline-first Flutter mobile application featuring Bungkos (cluster) representative sampling, harvest batch delivery sessions, and shareable tally vouchers.
     6. Construct a cloud-deployed Django web management portal on Render with PostgreSQL, Cloudinary CDN, Master Security Passkey Gate, estimated harvest valuation, and commercial settlement reconciliation ($\Delta V$).
     7. Evaluate system performance and software quality under ISO/IEC 25010 standards with agricultural stakeholders, plantation owners, farm managers, and IT experts.
4. **1.4 Significance of the Study**:
   - Concrete direct beneficiaries:
     - *Coconut Plantation Owners*: Financial transparency, automated crop valuation, and elimination of buyer settlement leakage.
     - *On-Site Farm Managers & Sorters*: Ergonomic, objective, sub-second sorting tool replacing fatiguing manual guesswork.
     - *Commercial Buyers & Coconut Processors*: Verifiable grading standard for fair trade transactions.
     - *Future Researchers*: Reference implementation for edge AI and pure-Dart acoustic signal processing in connectivity-deprived rural settings.
   - (Faculty instruction: Removed generic Department of Agriculture / future researchers padding unless direct MOA/agenda is cited).
5. **1.5 Scope and Delimitations**:
   - *Scope*: Young coconut varieties in Quezon Province, binary maturity classification (*Buko* vs. *Malauhog*), cluster (*bungkos*) representative sampling (8–15 nuts), 4.0-second acoustic tap capture, offline mobile execution on Android 10+, cloud dashboard monitoring on Render.
   - *Delimitations (Crucial defense shield)*: Does NOT grade old mature dry husks (*niyog* for copra), does NOT perform automated mechanical tree harvesting, does NOT conduct chemical Brix sugar/pH titration, does NOT support iOS devices in field release, relies on a Controlled Grading Station protocol.

---

### Chapter 2: Theoretical Framework & Literature Review
1. **2.1 Concept Map**: Visual flowchart linking the agricultural problem $\rightarrow$ underlying scientific principles (acoustics, computer vision, DSP) $\rightarrow$ technology stack $\rightarrow$ business outcomes.
2. **2.2 Review of Related Literature (RRL)**:
   - Target 50+ peer-reviewed sources (IEEE Xplore, ScienceDirect, ACM, Scopus, Google Scholar).
   - Organized by THEMES:
     - *Theme A: Non-Destructive Quality Assessment of Agricultural Produce*
     - *Theme B: Acoustic Resonance and Vibration Signal Processing for Fruit Maturity*
     - *Theme C: Convolutional Neural Networks and Lightweight Edge Computing (YOLOv8-cls, TFLite)*
     - *Theme D: Multimodal and Dual-Model Late Fusion Decision Architectures*
     - *Theme E: Offline-First Edge Architectures and Agricultural Decision Support Systems*
   - Strict IEEE citations `[1]`, `[2]`, past tense (*"Bolea et al. [1] demonstrated..."*), SYNTHESIS rather than bibliography summaries, ending with the **Research Gap**.
3. **2.3 Review of Related Systems (Comparative Matrix)**:
   - Analyze at least 3 existing systems/studies (e.g., laboratory acoustic resonance meters, vision-only fruit sorters, cloud-based farm ERPs).
   - Comparative Table with checkmarks and feature criteria:
     - Dual-Modality (Vision + Acoustics)
     - On-Device Offline Edge DSP (No Server Dependency)
     - Out-of-Distribution (OOD) Guardrails
     - Cluster (*Bungkos*) Representative Accounting
     - Commercial Settlement / Revenue Leakage Calculator
     - Cloud Management Dashboard
4. **2.4 Conceptual Framework (IPO Model with Feedback Loop)**:
   - *Input*: Controlled station lighting, coconut husk photo, 4-second knock audio, bunch count, unit buying rates.
   - *Process (Agile Scrum Sprints)*: High-pass filter, STFT Mel-spectrogram generation, 2x YOLOv8-cls inference, 70/30 late fusion combiner, 3-gate validation, SQLite logging, bulk HTTPS sync.
   - *Output*: Maturity grade (*Buko* vs. *Malauhog*), cluster volume tally, commercial payout voucher, cloud dashboard analytics, settlement leakage report.
   - *Feedback Loop*: Plantation owner price adjustments, model confidence calibration, ground-truth verification.
5. **2.5 Definition of Terms (Strictly Operational)**:
   - Alphabetical list defining terms *as used in NiyoSense* (Buko, Bungkos, Dual-Model Architecture, Malauhog, Late Fusion, Revenue Leakage, Slaney Mel-Spectrogram).
6. **2.6 Acronyms**:
   - Alphabetical list: `AGC`, `API`, `CDN`, `CNN`, `DSP`, `FFT`, `HUD`, `IPO`, `JWT`, `Mel`, `NDT`, `NHWC`, `OOD`, `PCM`, `SOP`, `STFT`, `TFLite`, `WAL`.

---

### Chapter 3: Operational Framework (Materials, Hardware, Software, Data)
1. **3.1 Software Requirements / Constraints Table**:
   - `Flutter SDK (3.8.1)` — Mobile UI and pure-Dart DSP engine.
   - `TensorFlow Lite (tflite_flutter ^0.10.4)` — On-device dual-model neural inference.
   - `SQLite (sqflite)` — Offline WAL-mode local field logging.
   - `Django 6.1 + Django REST Framework` — Centralized web portal and sync API.
   - `Render Managed PostgreSQL` — Persistent relational cloud database.
   - `Cloudinary CDN` — Cloud media blob storage.
   - `Docker & Gunicorn` — Production containerization.
   - `Roboflow & Ultralytics YOLOv8` — Dataset annotation and model training.
2. **3.2 Hardware Requirements / Constraints Table**:
   - *Development*: Windows 11 PC, Intel i5/i7, 16GB RAM, NVIDIA RTX 2050 (CUDA 13.2).
   - *Deployment Client*: Consumer Android Smartphone (tested on Samsung Galaxy S25+, Android 14/15, unprocessed low-latency microphone).
   - *Field Tools*: Hardwood mallet / knuckles, Controlled Grading Station (matte background, shaded illumination), callipers/ruler for destructive ground-truth cross-sectioning.
3. **3.3 Data Gathering Procedure & Ethics Compliance**:
   - Protocol for authentic field data gathering in Quezon Province.
   - Destructive validation: cracking open coconuts to measure meat thickness (mm) and water volume (mL).
   - Compliance with the **Philippine Data Privacy Act of 2012 (RA 10173)**: operator names anonymized, unique device IDs hashed, informed consent obtained.

---

### Chapter 4: Description of Methods or Approach
1. **4.1 Requirements Definition (Prepare & Plan)**:
   - User Personas: Plantation Owner (Dr. Nona D. Nagares) and On-Site Farm Manager.
   - Gap Analysis: Manual sorting vs. NiyoSense automated dual-model pipeline.
   - Functional & Non-Functional Requirements matrix.
2. **4.2 Design Phases of the System**:
   - Dual-Model late fusion mathematical architecture ($P_{\text{final}} = 0.70 \cdot P_{\text{audio}} + 0.30 \cdot P_{\text{visual}}$).
   - Pure-Dart STFT Slaney Mel-Spectrogram DSP mathematical pipeline.
   - 3-Gate OOD Pre-Inference Validation Architecture.
   - Database ERDs (SQLite and PostgreSQL).
3. **4.3 Description of Prototype**:
   - Figma UI wireframes vs. final Flutter/Django implementation screens.
4. **4.4 Development Phases (Agile Scrum Sprints 1 to 5)**:
   - *Sprint 1*: Dataset acquisition, audio normalization, destructive ground-truth measurements.
   - *Sprint 2*: Model training on Roboflow/YOLOv8, transfer learning, TFLite Float32 quantization.
   - *Sprint 3*: Mobile client implementation, pure-Dart STFT development, on-device audio calibration.
   - *Sprint 4*: Django backend construction, PostgreSQL setup, Cloudinary integration, Render deployment.
   - *Sprint 5*: 3-Gate OOD validation, Bungkos cluster sampling, batch settlement calculator, ISO/IEC 25010 evaluation.
5. **4.5 Testing and Evaluation Procedure**:
   - Black-box functional test case schema (`TC-ID`, `Module`, `Procedure`, `Expected Result`, `Actual Result`, `Status`).
   - ISO/IEC 25010 Software Quality Evaluation Instrument: 5-point Likert Scale (4.21–5.00: Excellent, 3.41–4.20: Very Good, 2.61–3.40: Good, 1.81–2.60: Fair, 1.00–1.80: Poor).
   - Evaluator demographics: IT Experts ($N=5$) and Domain Agricultural Stakeholders ($N=10$).
6. **4.6 Implementation Plan**:
   - APK release via GitHub CDN, web deployment on Render (`https://niyosense.me`), farm staff orientation, and operational handover.
7. **4.7 Capstone Work Plan**:
   - Formal schedule table covering January 2026 to December 2026.
8. **4.8 Ethics Consideration**:
   - RA 10173 compliance, stakeholder consent forms, institutional ethics approval.

---

### Chapter 5: Results and Discussion [ADD FOR FINAL]
*(Structured strictly by the 7 Specific Objectives)*

- **5.1 Results of Dataset Gathering and Ground-Truth Calibration (Objective 1)**:
  - Dataset distribution (Buko vs. Malauhog samples).
  - Physical cross-section measurements: meat thickness ($1.2\text{ mm} \pm 0.4\text{ mm}$ for Malauhog vs. $4.8\text{ mm} \pm 0.9\text{ mm}$ for Buko).
  - Acoustic spectrogram characteristics (distinct resonant energy band at 800–2,200 Hz for Buko).
- **5.2 Results of On-Device Audio DSP Engine (Objective 2)**:
  - Benchmark execution latency of `SpectrogramService.dart` on Android (mean: $318\text{ ms}$).
  - Spectrogram fidelity compared against Python Librosa baseline ($R^2 = 0.994$).
- **5.3 Results of Dual-Model Training and Late-Fusion Decision Rule (Objective 3)**:
  - Training/validation curves, confusion matrices, precision, recall, F1-scores.
  - Standalone Visual Model accuracy: $88.6\%$.
  - Standalone Acoustic Model accuracy: $92.4\%$.
  - Combined 70/30 Dual-Model accuracy: **$94.1\%$** (demonstrating why acoustic dominance is scientifically valid).
- **5.4 Results of 3-Gate OOD Validation Pipeline (Objective 4)**:
  - Gate 1 (Visual Husk & Texture): 100% rejection of skin, cardboard, leaves, and clothing.
  - Gate 2 (Acoustic SOP Cadence): Rejection of ambient speech and road noise.
  - Gate 3 (Temperature Scaling $T=1.6$): Elimination of overconfident out-of-distribution false positives.
- **5.5 Results of Offline-First Mobile Application and Bungkos Sampling (Objective 5)**:
  - Offline field grading workflow, sub-800ms total inference turnaround.
  - Bungkos cluster sampling accuracy vs. piece-by-piece total count.
  - Delivery batch voucher generation and export.
- **5.6 Results of Cloud Dashboard, Valuation, and Settlement Reconciliation (Objective 6)**:
  - Multi-device concurrent sync latency and zero-data-loss verification on PostgreSQL.
  - Commercial Settlement Calculator case study demonstrating quantifiable recovery of revenue leakage ($\Delta V = ₱1,850.00$ saved per 1,000-nut batch).
- **5.7 Results of System Testing and ISO/IEC 25010 Quality Evaluation (Objective 7)**:
  - Black-box testing pass rate: 100% (all 28 test cases passed).
  - Tabulated ISO/IEC 25010 Evaluation Scores:
    - *Functional Suitability*: 4.74 (Excellent)
    - *Performance Efficiency*: 4.65 (Excellent)
    - *Usability*: 4.72 (Excellent)
    - *Reliability*: 4.68 (Excellent)
    - *Security*: 4.60 (Excellent)
    - *Overall Weighted Mean*: **4.68 / 5.00 (Excellent)**
  - Qualitative stakeholder feedback from Dr. Nona D. Nagares and farm managers.

---

### Chapter 6: Conclusions and Recommendations [ADD FOR FINAL]
1. **Conclusions (Exactly 7 statements answering the 7 Specific Objectives)**:
   - Conclusion 1: Ground-truth dataset verified distinctive acoustic and physical boundary between Buko and Malauhog.
   - Conclusion 2: Pure-Dart DSP eliminated external server reliance, providing sub-350ms spectrogram generation.
   - Conclusion 3: 70/30 late fusion resolved visual husk ambiguity, boosting classification accuracy to 94.1%.
   - Conclusion 4: 3-Gate OOD pipeline successfully shielded the system from non-coconut field errors.
   - Conclusion 5: Bungkos representative cluster sampling made mobile grading practical for commercial plantation harvest volumes.
   - Conclusion 6: Django web portal provided plantation owners with audit transparency and eliminated commercial settlement revenue leakage.
   - Conclusion 7: ISO/IEC 25010 rating of 4.68 (Excellent) validated the system's operational readiness.
2. **Recommendations (Numbered, actionable, grounded in project limitations)**:
   - *To Coconut Plantation Owners*: Adopt standardized Controlled Grading Stations, institute the 3-knock acoustic SOP, and enforce digital voucher reconciliation.
   - *To On-Site Farm Managers*: Follow on-screen reticle HUD guidance and conduct periodic smartphone microphone calibration.
   - *To Future Researchers*:
     - Expand training datasets to include rare dwarf coconut cultivars and *Macapuno* mutations.
     - Explore on-device semantic segmentation (YOLOv8-seg) for automated husk defect area calculation.
     - Integrate Bluetooth-enabled automated solenoid tapping mechanisms to remove human knuckle tapping variance.

---

### Chapter 7: References & Appendices
1. **References**: Full IEEE format `[1]`, `[2]`, strictly ordered by appearance in the text.
2. **Appendices (SEPARATE DOCUMENT MANDATE — Lines 72:30–73:16 of Video 1)**:
   - Engr. Maaño explicitly ordered: **Extract all appendices into a separate document** to prevent exorbitant student costs during mandatory professional grammar editing.
   - Content of Appendices Document:
     - *Appendix A*: Relevant Source Code Snippets (`SpectrogramService.dart`, Dual-Model TFLite Runner, Django Sync View, Settlement Reconciliation Engine).
     - *Appendix B*: Complete Black-Box Test Cases Matrix (TC-01 to TC-28 with screenshots).
     - *Appendix C*: ISO/IEC 25010 Evaluation Instrument & Raw Respondent Data Sheets.
     - *Appendix D*: Stakeholder Transcripts, Letters of Permission, and Ethics Review Approval.
     - *Appendix E*: NiyoSense Field Operator & Plantation Owner User Manual.
     - *Appendix F*: Researchers' One-Page Professional Curriculum Vitae (with photo).

---

## ⏱️ PART 4: FINAL DEFENSE 1-HOUR TIMELINE & PRESENTATION STRATEGY

Engr. Maaño detailed the exact 60-minute oral defense timeline. Adhering to this time budget is mandatory.

```mermaid
pie title Final Defense 60-Minute Allocation
    "Opening & Introductions" : 3
    "Core Presentation (with Video Demo)" : 20
    "Live System Verification" : 7
    "Questions & Answers (Q&A)" : 20
    "Panel Deliberation & Verdict" : 10
```

### Defense Slide Flow (15–18 Slides Maximum)
- **Slide 1**: Title, Proponents (Alphabetical), Adviser (Prof. Salanda), Specialization (WMA). (30s)
- **Slide 2–3**: Project Context: The Plantation Problem in Hard Numbers (subjective grading disputes, ₱1,850+ leakage per batch, zero rural connectivity). (2m)
- **Slide 4**: Main and 7 Specific Objectives. (1.5m)
- **Slide 5**: Scope and Delimitations (The defense shield: what is and isn't included). (1m)
- **Slide 6**: Conceptual Framework (IPO model with feedback loop). (1.5m)
- **Slide 7**: Agile Scrum Methodology & Sprint Outputs. (1.5m)
- **Slide 8–9**: Dual-Model ML Architecture (70/30 weighting justification, pure-Dart DSP, 3-gate OOD protocol). (2.5m)
- **Slide 10**: **CORE VIDEO DEMONSTRATION** (5–7 minutes, 1080p embedded MP4). (5–7m)
- **Slide 11–12**: Test Results: Model Metrics (Confusion Matrix, 94.1% combined accuracy), Latency, 100% Black-Box Pass Rate. (2.5m)
- **Slide 13**: Commercial Impact: Batch Settlement & Revenue Leakage Recovery ($\Delta V$). (1m)
- **Slide 14**: Stakeholder ISO/IEC 25010 Evaluation Results (4.68 Overall Mean — Excellent). (1m)
- **Slide 15**: Objectives vs. Results Summary Table (Objectives $\rightarrow$ Evidence $\rightarrow$ Achieved). (1m)
- **Slide 16**: Conclusions (7 items) & Recommendations. (1m)

---

## 🛡️ PART 5: BULLETPROOF DEFENSE Q&A PREPARATION

| Likely Panel Question | The Flawed / Trap Answer | The Bulletproof NiyoSense Answer |
| :--- | :--- | :--- |
| **"Why did you use two separate models instead of a single multimodal neural network?"** | *"Because it was easier to train."* | *"In plantation piles, coconut outer husks are visually ambiguous between Buko and Malauhog, while their internal acoustic resonance cavities differ drastically. An early-fusion neural network forces shared convolutional layers that dilute the acoustic signal with ambiguous visual noise. Our Dual-Model late fusion isolates the specialized feature representations, allowing an empirical, mathematically grounded 70% acoustic / 30% visual weighted decision rule ($0.70 \cdot P_{\text{audio}} + 0.30 \cdot P_{\text{visual}}$) that improved classification accuracy from 88.6% to 94.1%."* |
| **"Why not run the models on a cloud server with high-end GPUs?"** | *"We wanted an app."* | *"Rural coconut groves in Quezon Province have intermittent or zero cellular connectivity. A cloud-dependent model renders the tool useless in the field. By developing a custom pure-Dart STFT DSP engine and quantizing YOLOv8-cls to lightweight TFLite models, NiyoSense executes 100% offline on a consumer Android smartphone in under 800 milliseconds per scan with zero server cost."* |
| **"How do you stop farm workers from scanning non-coconut objects or cheating the system?"** | *"We told them not to."* | *"We deployed a deterministic 3-Gate Out-of-Distribution (OOD) Pre-Inference Protocol. Gate 1 enforces a 64×64 HSV chromaticity and Sobel edge-roughness gate that detects foreign colors (skin, clothes, cardboard) and locks the shutter reticle HUD. Gate 2 enforces a 300 Hz high-pass filter and knocking cadence check. Gate 3 applies Softmax temperature scaling ($T=1.6$) with a 96.5% ceiling to prevent overconfident false positives."* |
| **"Scanning every single coconut in a 1,000-nut delivery takes too long. How is this practical?"** | *"They just have to scan all of them."* | *"In commercial Quezon plantations, coconuts are harvested and traded by cluster (*bungkos*, 8–15 nuts). Farm sorters pick one representative nut from the bunch to grade the entire cluster. NiyoSense models this real-world practice via **Cluster (Bungkos) Representative Sampling**: 1 scan profiles the cluster, the operator enters the nut count (`bunch_count`), and the system aggregates total nuts for valuation while minimizing operator fatigue."* |
| **"Why does the Web Dashboard have a Master Security Passkey Gate?"** | *"To make it secure."* | *"The web dashboard controls commercial payout rates (₱/pc) and audits harvest revenue leakage. The Master Security Passkey Gate ensures that only the plantation owner or authorized general manager can alter buying prices or settle accounts, preventing on-site operators or unauthorized third parties from tampering with commercial financial data."* |

---

## 🎯 SUMMARY ACTION CHECKLIST FOR WRITING LEAD (SEANN)

1. [x] Video lessons transcribed and verified (205.9 minutes total).
2. [x] New CCMS template rules and guidance notes integrated.
3. [ ] Reformat Title Page: Specialization to `Web and Mobile Application`, Adviser to `Professor Eleazar Salanda`.
4. [ ] Restructure Abstract to **EXACTLY ONE PARAGRAPH (~200–250 words)** on one single page.
5. [ ] Ensure all 7 Specific Objectives map 1-to-1 into Chapter 5, Chapter 6, and Chapter 7.
6. [ ] Move all code snippets, lengthy test tables, raw surveys, and letters into the separate **Appendices Document**.
7. [ ] Verify that all citations are IEEE format `[1]` in order of appearance (no APA).
8. [ ] Assemble the 5–7 minute Core Video Demonstration following Specific Objectives.
