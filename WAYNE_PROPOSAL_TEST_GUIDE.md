# Testing Wayne's Proposal (Branch: `feature/leader-proposal-test`)

This document outlines the evaluation and step-by-step test procedure for Wayne's proposal (Plantation Owner persona, Zero-Friction QR Identity Handshake, and Financial Valuation / Net Profit Reconciliation Engine).

---

## 1. Summary of Changes Implemented

### A. QR-Based Device Identity (Zero-Friction Authentication)
* **Web Dashboard Handshake:**
  * Endpoint: `/api/v1/auth/pair-token/`
  * Automatically issues a cryptographic pairing token in a single JSON payload:
    ```json
    {
      "farm_id": "PLANTATION-01",
      "token": "eyJhbGciOi...",
      "host_ip": "http://192.168.1.100:8000",
      "username": "farm_worker"
    }
    ```
* **Mobile Scanner Handshake:**
  * Added **"Scan Plantation QR (Instant Login)"** on the mobile login screen.
  * When scanned, the app automatically extracts `farm_id`, `access_token`, and `host_ip`, authenticating the device in 1 second without typing usernames or passwords.

### B. Monthly Maturity Ratio (Donut Chart)
* Replaced arbitrary multi-stage charts in the Analytics tab with Wayne's **2-Category Donut Chart**:
  * **Malauhog** (Amber `#F59E0B`)
  * **Buko / Mature** (Emerald Green `#10B981`)
* Center metric dynamically displays the **Total Monthly Count**.
* Legend displays raw unit counts alongside batch percentages.

### C. Estimated Valuation Engine (Gross Expected Batch Value)
* Real-time calculation based on Wayne's formula:
  $$\text{Estimated Gross Value} = (N_{\text{malauhog}} \times P_{\text{malauhog}}) + (N_{\text{buko}} \times P_{\text{buko}})$$
* Configurable live defaults:
  * Malauhog Price ($P_{\text{malauhog}}$): Default ₱20.00 / pc
  * Buko Price ($P_{\text{buko}}$): Default ₱15.00 / pc
* Dynamic card displays total expected revenue immediately upon typing.

### D. Financial Reconciliation & Net Profit Audit (Estimated vs. Actual Net P&L)
* Side-by-side reconciliation tool:
  * **Direct Harvesting Expenses:**
    $$\text{Total Labor} = (N_{\text{malauhog}} + N_{\text{buko}}) \times \text{Labor Rate per Nut (₱2.50 default)}$$
  * **Commercial Price Variance (Leakage):**
    $$\text{Variance} = \text{Actual Cash Received} - \text{Estimated Gross Value}$$
    * If negative ($-₱$): Flags that the buyer paid below grade value (unfair flat-rate discount / commercial leakage).
    * If positive/zero ($+₱$): Confirms owner captured full graded market premium.
  * **Realized Net Profit:**
    $$\text{Net Profit} = \text{Actual Cash Received} - \text{Total Labor}$$

---

## 2. How to Test Wayne's Implementation

### Test Step 1: Run Django Backend
```powershell
cd D:\desktop\GITHUB\niyosense-capstone\backend
.\.venv\Scripts\python.exe manage.py runserver 0.0.0.0:8000
```
Open [http://127.0.0.1:8000/](http://127.0.0.1:8000/) in your browser.

### Test Step 2: Test the Financial Valuation & Reconciliation
1. On the web dashboard, click **📊 Analytics**.
2. Notice the **Monthly Maturity Ratio** donut chart showing the Malauhog vs. Buko split.
3. In the **Estimated Valuation Engine**, change Malauhog price (e.g., ₱22) and Buko price (e.g., ₱16) — watch the **Estimated Gross Batch Value** recalculate live.
4. In the **Batch Settlement & Profit Reconciliation** card:
   * Enter what the buyer paid you in **Actual Received** (e.g., `₱20,500.00`).
   * Enter the climbing crew rate in **Labor Rate** (e.g., `₱2.50 / nut`).
   * Watch the **Commercial Price Variance (Leakage)** turn red (shortfall) or green (premium), and view the **Realized Net Profit**.

### Test Step 3: Test Instant QR Device Identity (Zero-Friction Login)
1. On the web dashboard, click **⚙️ Settings** $\rightarrow$ click **📷 Scan QR Code**.
2. In your Flutter mobile app (on emulator or phone):
   * On the Login screen, tap **"Scan Plantation QR (Instant Login)"**.
   * Aim the camera at the web dashboard QR code.
   * **Result:** The mobile app pairs and logs in immediately without manual username or password input!
