# 🥥 NiyoSense: Guide on Bungkos (Cluster) Sampling for Leader & Panel Review

**Branch:** `feature/web-bungkos-sampling`  
**Live Test Link (No Setup Needed):** [https://relief-bay-prostate-drama.trycloudflare.com/](https://relief-bay-prostate-drama.trycloudflare.com/)  
*(Or locally if on the same machine: [http://localhost:8080/](http://localhost:8080/))*

---

## 📌 Part 1: How to Explain It (The "Why & How" Pitch)

When explaining this to your leader or thesis panel, use this narrative:

> *"In real-world Philippine coconut farming (PCA standards and local trading practice in Quezon and Laguna), farmers do not grade all 1,000 coconuts one by one on the tree or pile. Instead, they cut down coconuts in **clusters or bunches (bungkos)**.*
>
> *Because all coconuts in a single cluster developed at the exact same flowering time, **1 coconut sampled from that bunch represents the maturity baseline for the whole bunch (around 8–14 nuts)**.*
>
> *Our mobile app guides the worker to sample 1 nut per bungkos. To ensure the **Web Dashboard** matches this real commercial reality, we updated the dashboard so the plantation owner sees both the **sampled bunches** and the **true estimated coconut harvest volume and financial revenue**."*

---

## 🧪 Part 2: Step-by-Step Testing Guide for Your Leader

Here is the exact 3-step walkthrough for your leader to verify the feature:

### Step 1: Check the Home Overview (SOP Transparency)
1. Open [https://relief-bay-prostate-drama.trycloudflare.com/](https://relief-bay-prostate-drama.trycloudflare.com/).
2. Look at the top of the **Home** tab.
3. **What to look for:**
   - Notice the green informational banner:
     > **🌿 Cluster (Bungkos) Sampling Protocol Active**  
     > *Each field scan grades 1 representative sample nut per harvest cluster. The result sets the baseline maturity for that entire bunch (bungkos).*
   - Look beside the date filter badge for the metadata tag: `📦 1 Scan = 1 Bunch (Bungkos)`.

---

### Step 2: Check the Inspection Logs (Sampling Unit Badge)
1. Click on the **Logs** tab (or **Audit Logs** in sidebar).
2. Look at the table columns.
3. **What to look for:**
   - There is a new **Sampling Unit** column.
   - Each row displays an emerald pill badge: `🌿 Bungkos (Bunch)`.
   - Hovering over it explains that this record represents a harvested bunch baseline.

---

### Step 3: Test the Interactive Valuation Multiplier (Analytics Tab)
1. Click on the **Analytics** tab.
2. Scroll to the **Estimated Valuation Engine** (Gross Value card).
3. **What to look for:**
   - You will see 3 inputs side-by-side:
     - `Malauhog Price (₱/pc)` (default: `20.00`)
     - `Buko Price (₱/pc)` (default: `15.00`)
     - **`🌿 Nuts / Bungkos` (default: `10`)** 👈 *New input*
4. **Try changing the numbers:**
   - If you change **`Nuts / Bungkos` from `10` to `1`**, the formula calculates individual loose nuts (e.g. 5 bunches = 5 nuts).
   - If you set it to **`12`**, notice how the **Estimated Gross Batch Value** and the subtitle text instantly update in real-time:
     > *"Based on 2 bunches (~24 nuts) @ ₱20 + 3 bunches (~36 nuts) @ ₱15 (×12/bungkos)"*
5. Scroll down to the **Batch Settlement & Profit Reconciliation** card:
   - Notice that the **Harvester Labor Cost** (`₱2.50/nut`) now automatically multiplies across all nuts in the bunches, accurately calculating the true Net Profit and price leakage variance!

---

## 🎯 Part 3: What Decision is Needed from the Leader?

Ask your leader:
1. **Is the wording clear?** (Do you prefer the term *"Bungkos"*, *"Cluster"*, or *"Bunch"*?)
2. **Is the default multiplier of 10 nuts/bunch appropriate?** (Farm owners can always change this live in the input box).
3. **Approval to merge:** Once satisfied, we can run:
   ```bash
   git checkout main
   git merge feature/web-bungkos-sampling
   git push origin main
   ```
