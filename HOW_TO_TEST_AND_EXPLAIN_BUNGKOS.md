# 🥥 NiyoSense: Guide on Bungkos (Cluster) Sampling for Leader & Panel Review

**Branch:** `feature/web-bungkos-sampling`  
**Live Test Link (No Setup Needed):** [https://relief-bay-prostate-drama.trycloudflare.com/](https://relief-bay-prostate-drama.trycloudflare.com/)  
*(Or locally if on the same machine: [http://localhost:8080/](http://localhost:8080/))*

---

## 📌 Part 1: How to Explain It (The "Why & How" Pitch)

When explaining this to your leader or thesis panel, use this narrative:

> *"In real-world Philippine coconut farming (PCA standards and local trading practice in Quezon and Laguna), farmers do not grade all 1,000 coconuts one by one on the tree or pile. Instead, they cut down coconuts in **clusters or bunches (bungkos)**.*
>
> *Because all coconuts in a single cluster developed at the exact same flowering time, **1 coconut sampled from that bunch represents the maturity baseline for the whole bunch (around 8–15 nuts)**.*
>
> *Now, right after scanning the representative coconut on the **Mobile App**, the worker enters **how many coconuts are in that bungkos** (e.g., 10 or 12 pcs, with quick-tap presets). When synced to the **Web Dashboard**, the database records the actual coconut count from each bunch—so all KPIs, charts, audit logs, and financial payout calculations reflect true harvested coconut volume rather than counting by 1."*

---

## 📱 Part 2: Mobile App Update (Field Worker Side)

On the **Scan Results Screen** (`lib/views/scan_result_screen.dart`), inside the **Cluster Maturity Baseline** card:
1. **Interactive Bungkos Coconut Counter:**
   - Includes **`-` / `+` stepper buttons** and a **direct numeric input box** (defaults to `10` coconuts per bunch).
   - Includes **1-tap preset chips**: `1 (Single)`, `8 pcs`, `10 pcs`, `12 pcs`, `15 pcs`.
2. **Real-Time SQLite & Sync Integration:**
   - Saves `bunch_count` to local SQLite (`grading_logs` table v4) and automatically links to any active Farmer Delivery Session.
   - Syncs `bunch_count` to the Django/PostgreSQL backend via `/api/v1/sync/bulk-logs/`.

---

## 🧪 Part 3: Step-by-Step Web Dashboard Testing Guide for Your Leader

Here is the exact 3-step walkthrough for your leader to verify the feature on the live dashboard:

### Step 1: Check the Home Overview (True Coconut Volume vs. Bunches Sampled)
1. Open [https://relief-bay-prostate-drama.trycloudflare.com/](https://relief-bay-prostate-drama.trycloudflare.com/).
2. Look at the top of the **Home** tab.
3. **What to look for:**
   - The green **Cluster (Bungkos) Sampling Protocol Active** banner shows the total number of bunches sampled (`📦 21 Bunches Sampled`).
   - The **Total Coconuts Graded (from Bunches)** card (`156`) sums the actual `bunch_count` across all bunches rather than just counting 1 per scan!
   - The **Daily Maturity Report** and **Maturity Distribution** charts also plot true coconut counts.

---

### Step 2: Check the Inspection Logs (Exact Coconuts per Bungkos)
1. Click on the **Grading Logs** tab in the sidebar.
2. Look at the **Sampling Unit** column.
3. **What to look for:**
   - Each scan record displays the exact bunch size entered by the worker: e.g., **`🌿 10 pcs in Bungkos`**.

---

### Step 3: Check the Analytics & Valuation Engine
1. Click on the **Analytics** tab.
2. Look at the **Monthly Maturity Ratio** and **Estimated Valuation Engine**.
3. **What to look for:**
   - All counts (`150 Malauhog` etc.) now already reflect the summed coconuts from the bunches.
   - The **Estimated Gross Batch Value** and **Batch Settlement & Profit Reconciliation** (including harvester labor cost per nut) automatically use the real coconut volume from the bunches.

---

## 🎯 Part 4: Decision for the Leader

Ask your leader:
1. **Does the mobile input + dashboard bunch summation match the team's workflow?**
2. **Approval to merge:** Once approved, we can merge `feature/web-bungkos-sampling` into `main` and build the updated APK!
