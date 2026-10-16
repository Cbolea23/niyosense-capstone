# NiyoSense Web Dashboard: Bungkos (Cluster Sampling Protocol) Feature Review

**Target Audience:** Project Leader & Research Advisors  
**Git Branch:** `feature/web-bungkos-sampling`  
**Deployment Preview:**
- **Local:** [http://localhost:8080/](http://localhost:8080/)
- **Live Cloudflare Tunnel:** [https://alan-bobby-internship-components.trycloudflare.com/](https://alan-bobby-internship-components.trycloudflare.com/)

---

## 1. Context & Motivation

In Philippine commercial coconut farming (e.g., Quezon, Laguna, Batangas), harvesters and aggregators do not grade every single coconut individually due to time, labor, and tree-canopy harvest dynamics. Instead, standard agricultural practice relies on **cluster-level sampling**:
- **1 sampled coconut** from a freshly brought down bunch (*bungkos*) represents the baseline maturity state for all coconuts in that cluster (typically 8–14 nuts per bunch).

While our mobile app instructions guide the farmer to sample one representative nut from the cluster, the **Web Dashboard** previously displayed raw numbers as individual loose nuts. This created a discrepancy between:
1. What the plantation owner sees on the dashboard vs.
2. The real volume and economic yield harvested in the field.

---

## 2. Features Implemented on Branch `feature/web-bungkos-sampling`

### A. Home Dashboard: Active Sampling Protocol Banner
- **Location:** `backend/templates/dashboard/includes/tab_home.html`
- **Visual:** Added an emerald informational callout at the top of the summary view:
  > **Cluster (Bungkos) Sampling Protocol Active**  
  > *Each field scan grades 1 representative sample nut per harvest cluster. The result sets the baseline maturity for that entire bunch (bungkos).*
- Added a `📦 1 Scan = 1 Bunch (Bungkos)` metadata indicator next to batch timestamps.

### B. Grading Logs: Cluster Unit Indicators
- **Location:** `backend/templates/dashboard/includes/tab_logs.html`
- Added a dedicated **Sampling Unit** column in the inspection table displaying:
  - `🌿 Bungkos (Bunch)` badge on each scan record.
  - Hover tooltips explaining that this record represents a cluster harvest baseline.

### C. Analytics & Valuation Engine: Bunch Multiplier (`Nuts / Bungkos`)
- **Location:** `backend/templates/dashboard/includes/tab_analytics.html` & `backend/templates/dashboard/index.html`
- **What was changed:**
  - Added an interactive input field: **`🌿 Nuts / Bungkos`** (Default: `10`, min: `1`).
  - **Dynamic Valuation Formula:**
    $$\text{Total Nuts} = (\text{Sampled Bunches}) \times \text{NutsPerBunch}$$
    $$\text{Gross Value} = (\text{Malauhog Bunches} \times \text{Multiplier} \times P_{\text{malauhog}}) + (\text{Buko Bunches} \times \text{Multiplier} \times P_{\text{buko}})$$
  - **Labor & Reconciliation Impact:**
    - The climber/harvester labor cost (`₱2.50/nut`) and net profit variance now automatically calculate against the **true total nuts** in the batch, rather than only the single sampled nut.
  - **Flexibility:** If a user scans individual loose nuts, they can set `Nuts / Bungkos = 1`. If they harvest in bunches, setting it to `10` or `12` reflects realistic commercial yield.

---

## 3. Code & Files Modified

| File | Changes |
| :--- | :--- |
| `backend/templates/dashboard/includes/tab_home.html` | Added SOP cluster sampling notice banner & unit badge |
| `backend/templates/dashboard/includes/tab_logs.html` | Added "Sampling Unit" column with `Bungkos (Bunch)` badge |
| `backend/templates/dashboard/includes/tab_analytics.html` | Added `Nuts / Bungkos` input field to formula row |
| `backend/templates/dashboard/index.html` | Updated `recalculateValuation()` & `recalculateReconciliation()` math |

---

## 4. Verification & Testing

- [x] Syntax checked across all Jinja2 templates and HTML/JS script blocks.
- [x] Deployed and hot-reloaded into Docker test container `niyosense_leader_test`.
- [x] Verified via curl and browser live rendering on `localhost:8080` and Cloudflare tunnel.
- [x] Isolated on git branch `feature/web-bungkos-sampling` (unmerged to `main`).

---

## 5. Decision for Project Leader

1. **Approve & Merge:** If the UI labels and cluster math match your vision, run:
   ```bash
   git checkout main
   git merge feature/web-bungkos-sampling
   git push origin main
   ```
2. **Revisions:** If wording, default multiplier values, or layout need adjustment, reply with feedback and we will fine-tune the branch before merging.
