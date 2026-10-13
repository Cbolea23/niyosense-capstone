# NiyoSense - Enhanced Field Grading & Farm Owner Intelligence System

**Project Version:** `v1.3.4` (TFLite INT8 Multimodal Pipeline v2.4.1)  
**Public Live Test URL:** [https://meals-screenshot-correction-maritime.trycloudflare.com/](https://meals-screenshot-correction-maritime.trycloudflare.com/)  
**Local Test Container Port:** `http://127.0.0.1:8080` (Internal port `8000`)

---

## 📌 Executive Summary

This branch refines NiyoSense into a clean, dual-platform system:
1. **A Streamlined Mobile Field App (Flutter / Android):** Eliminates unnecessary delivery session clutter and broken QR identity pairing. Field aggregators simply log in with standard credentials, run instant multimodal AI coconut maturity inspections (camera + acoustic resonance tap), and store/sync grading logs tagged with a **persistent hardware Device ID**.
2. **An Advanced Farm Owner Intelligence Dashboard (Django / Tailwind / Chart.js):** Provides farm owners with customizable farm profiling, aggregator credential management, live harvest yield metrics, and Wayne's proposal features: **Monthly Maturity Split**, **Estimated Valuation Engine (Gross Value)**, and **Settlement Reconciliation Card (Profit & Commercial Leakage Audit)**.

---

## 📋 Changes from the Leader's Proposal Paper & Technical Justifications

During empirical field testing and implementation of the proposal paper (`D:\downloads\new propose`), several modifications and refinements were made. Below is the side-by-side comparison explaining what changed from the written proposal and why:

| Proposal Concept | Original Paper Proposal | Implemented Evolution | Rationale & Root Cause |
|---|---|---|---|
| **Field Authentication & Worker Identity** | Single-step QR scanning to automatically provision operator credentials and log in without username/password. | Restored dedicated **Username + Password login** on mobile, with an administrative **Manage Aggregators** web panel to provision worker credentials. | **JWT Invalidation & Sync Failure:** QR-only auto-pairing embedded a short-lived bearer token without storing worker credentials on the device. When workers conducted offline harvests or when tokens expired, background sync failed (`401 Unauthorized / Authentication required`) because the client could not refresh credentials without user credentials on disk. In real plantations with intermittent cellular coverage, persistent credential caching with refresh tokens is mandatory. |
| **Hardware & Handheld Identity** | Static placeholder device string (`NYS-FIELD-0024`) displayed on mobile settings. | **Persistent, Unique Hardware ID (`NYS-DEV-XXXXXX`)** generated per physical installation, stored in `SharedPreferences`, tagged onto each SQLite scan, and recorded in Django. | **Audit Trails & Hardware Defect Tracking:** In field logistics, multiple workers share or rotate phones. If camera lenses crack or microphone ports clog, farm owners need to isolate which physical device captured faulty readings rather than just who logged in. A static string rendered device analytics useless across multiple testing phones. |
| **Delivery Sessions & Batches (Mobile UI)** | Dedicated "Farmer Delivery Session" card on the mobile home screen requiring workers to name suppliers and open/close sessions. | **Streamlined One-Tap Grading:** Removed farmer delivery session cards from mobile home and scan result screens; scans grade and persist immediately with Device ID. | **Field Friction & Worker Simplicity:** Real field aggregators and tree harvesters operate in high-pace harvesting environments where typing supplier names and managing multi-step batches causes bottlenecks. Graded tallies flow naturally into the farm's aggregated inventory, where the farm owner can reconcile batches on the web dashboard. |
| **Farm Owner Profile** | Hardcoded visual placeholder ("Maria Santos • Santos Coconut Farm • Quezon Province"). | **Dynamic `FarmProfile` Database Model & Editable Web Modal:** Farm owners can customize their name, farm name, location, and email directly from the Settings tab. | **Multi-Tenant / Multi-Farm Usability:** A production capstone project cannot feature hardcoded farm owner personas. The farm owner can now personalize their dashboard, which automatically updates the top greeting banner, sidebar branding, and report headers. |
| **Commercial Analytics & Valuation Engine** | Static mockup wireframes showing estimated gross batch values and reconciliation formulas. | **Interactive, Real-Time Valuation Engine & Audit Tool:** Live inputs for *Malauhog Price*, *Buko Price*, *Buyer Cash Received*, and *Climber Labor Rate* that calculate gross value, net take-home profit, and commercial price leakage with dynamic visual indicators ($📉$ / $📈$ / $⚖️$). | **Practical Commercial Utility:** Farm owners deal with varying coconut buying rates per day and negotiating with buyers. Providing dynamic calculation inputs directly proves the economic value of AI grading over flat-rate middleman exploitation. |

---

## 🌟 What's New & Refined

### 1. Mobile Field Operator App (Flutter)
- **Manual Credential Login (Restored & Hardened):**
  - Replaced the experimental QR-only login screen with the dedicated **Field Operator Login** interface.
  - Workers sign in with their assigned username and password.
  - Automatic JWT authentication and seamless sequential background token renewal prevent `401 Unauthorized` errors.
- **Truly Unique & Persistent Device ID (`NYS-DEV-XXXXXX`):**
  - Replaced the static placeholder string (`NYS-FIELD-0024`) with an auto-generated, persistent hardware identifier stored in `SharedPreferences`.
  - Every scan saved to local SQLite (`niyosense_local.db`) is tagged with this ID.
  - The Device ID is uploaded during sync and recorded in Django for hardware tracking and equipment auditing.
- **Streamlined Workflow (Clutter Removed):**
  - Removed "Farmer Delivery Sessions" from the home screen and scan flow.
  - Operators can immediately tap the center button to begin scanning without having to create or manage delivery batches.
- **OTA Update Checker & Direct APK Download:**
  - Integrated in-app update checks (`UpdateService`) that ping the server to ensure field workers always run the latest model engine.

### 2. Farm Owner Web Dashboard (Django Web App)
- **Farm Owner Greeting & Live Time Banner:**
  - Displays a personalized greeting on the Home tab:  
    > *"Good day, `<Owner Name>`! Welcome back to `<Farm Name>`. Here is your farm's harvest overview today."*
  - Shows live timestamps and quick links to valuation and settings.
- **Dynamic & Editable Farm Owner Profile:**
  - Removed the static "Maria Santos" placeholder.
  - Added an **✏️ Edit Profile** modal under **Settings** where the owner can update their name, farm/plantation name, province/location, and contact email.
  - Changes instantly update the database, sidebar branding, profile badge, and home greeting.
- **Wayne's Commercial Valuation & Reconciliation Modules (Analytics Tab):**
  - **Monthly Maturity Ratio (Donut Chart):** Visualizes current month volume splits between high-value meat (Mature/Buko) and tender nuts (Malauhog) with percentages and total count.
  - **Estimated Valuation Engine:** Calculates expected gross batch revenue:
    $$\text{Gross Value} = (\text{Malauhog Count} \times \text{Malauhog Price}) + (\text{Mature Count} \times \text{Mature Price})$$
  - **Batch Settlement & Profit Reconciliation:** Side-by-side reconciliation tool:
    - **Direct Labor Overhead:** $\text{Total Nuts} \times \text{Climber Labor Rate}$
    - **Actual Realized Net Profit:** $\text{Actual Buyer Payout} - \text{Direct Labor Overhead}$
    - **Commercial Price Variance (Leakage):** $\text{Actual Buyer Payout} - \text{Estimated Graded Gross Value}$ with real-time indicators ($📉$ *Price Leakage*, $📈$ *Premium Pricing*, or $⚖️$ *Balanced*).
- **Manage Aggregators (Restored & Enhanced):**
  - Allows farm owners to create field operator accounts directly from the web dashboard.
  - When an account is created, an interactive row with an **⚙️ Edit** button appears immediately without requiring a full page reload.
  - Admins can view login credentials, copy them, reset passwords, or disable worker accounts.
- **Device Tracking in Grading Logs:**
  - Added a dedicated **Device** column in the **Grading Logs** table displaying each scan's originating `device_id`.
- **Dynamic System Metadata:**
  - Reflects active project versions (`v1.3.4`, `Multimodal Audio-Visual v2.4.1`, `TFLite (INT8 Quantized)`).

---

## 🛠️ System Architecture & Ports

| Component | Technology | Local / Internal Port | External Tunnel / Access |
|---|---|---|---|
| **Test Backend (Leader Branch)** | Django 5.x / PostgreSQL / Gunicorn | `8080` (Host) $\rightarrow$ `8000` (Docker) | `https://meals-screenshot-correction-maritime.trycloudflare.com` |
| **Original Backend** | Django 5.x / PostgreSQL | `8000` (Host, untouched) | - |
| **Mobile App** | Flutter 3.x / Dart / SQLite / TFLite | Android Device / Emulator | Connects via Cloudflare tunnel or LAN IP |
| **Database** | PostgreSQL (Docker volume) | `5432` | Container internal |

---

## 🚀 How to Run & Test

### Step 1: Accessing the Web Dashboard
1. Open your browser and navigate to:
   ```
   https://meals-screenshot-correction-maritime.trycloudflare.com/
   ```
2. **Test Farm Profile Customization:**
   - Go to **Settings** $\rightarrow$ click **✏️ Edit Profile**.
   - Change the Farm Owner Name (e.g., your name) and Farm Name, then click **Save Farm Profile**.
   - Notice the updated greeting banner on the **Home** tab and the updated branding in the sidebar.
3. **Test Aggregator Account Creation:**
   - Go to **Manage Aggregators**.
   - Fill in a Username and Password (min. 6 chars) $\rightarrow$ click **➕ Create Operator Account**.
   - Notice the new operator row appears with an **⚙️ Edit** button.
   - Click **Edit** to view the credentials modal, test the show/hide password toggle, and copy the credentials.
4. **Test Wayne's Valuation & Reconciliation Engine:**
   - Go to **Analytics**.
   - Adjust the **Malauhog Price** and **Buko Price** inputs in the **Estimated Valuation Engine** to observe the Gross Batch Value calculation update live.
   - Adjust the **Actual Received** and **Climber/Harvester Labor Rate** inputs in the **Batch Settlement & Profit Reconciliation** card to test the real-time net take-home profit and commercial leakage indicators.

---

### Step 2: Testing the Mobile App (Android)

#### A. Installing the APK
- **Direct Download:** You can download the latest compiled APK from the dashboard under **Settings** $\rightarrow$ **Download APK** or by scanning the APK QR code.
- **Via ADB (For Connected Devices):**
  ```powershell
  & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r build\app\outputs\flutter-apk\app-release.apk
  ```

#### B. Logging In & Connecting
1. Launch **NiyoSense** on your Android phone.
2. If pairing for the first time, tap the QR icon at the top right of the login screen and scan the **Server Configuration** QR code found in the dashboard's **Settings** tab (or type the tunnel URL: `https://meals-screenshot-correction-maritime.trycloudflare.com`).
3. Enter your field aggregator credentials (e.g., `farm_worker` or any new account created under Manage Aggregators) and tap **Sign In**.

#### C. Recording Scans & Verifying Unique Device ID
1. On the Home screen, tap **Start Coconut Scan**.
2. Complete a visual camera scan and optional acoustic resonance tap.
3. On the result screen, the scan is automatically saved to local SQLite and tagged with your phone's unique `device_id`.
4. Tap **Sync** on the Home screen to upload the offline records to the cloud.
5. Check the dashboard's **Grading Logs** tab to confirm your scan appears with its classification, confidence score, media files, operator name, and unique **Device ID**.
6. Check the app's **Settings** screen to view your phone's persistent **Device ID** under device info.

---

## 📁 Key File Modifications

| File Path | Description |
|---|---|
| `backend/apps/scans/models.py` | Added `FarmProfile` model and `device_id` column to `GradingLog`. |
| `backend/apps/scans/views.py` | Implemented `farm_profile_api`, added dynamic context variables (`app_version`, `farm_profile`), and bound `device_id`. |
| `backend/apps/scans/serializers.py` | Added `device_id` field to `BulkSyncGradingLogSerializer`. |
| `backend/templates/dashboard/index.html` | Restored Aggregator modal scripts, dynamic edit triggers, and implemented Wayne's valuation and profit reconciliation math. |
| `backend/templates/dashboard/includes/sidebar.html` | Dynamic farm name binding; removed `Deliveries & Payouts`. |
| `backend/templates/dashboard/includes/tab_home.html` | Added personalized Farm Owner greeting banner and live clock. |
| `backend/templates/dashboard/includes/tab_analytics.html` | Wayne's Monthly Ratio Donut, Estimated Valuation Engine, and Settlement Reconciliation Card. |
| `backend/templates/dashboard/includes/tab_aggregators.html` | Full aggregator account management, password viewing/resetting, and active status toggling. |
| `backend/templates/dashboard/includes/tab_settings.html` | Added Farm Profile editing modal and dynamic version metadata card. |
| `backend/templates/dashboard/includes/tab_logs.html` | Added **Device** column to display origin hardware ID. |
| `lib/main.dart` | Restored manual credential login flow; removed Farmer Delivery Session cards. |
| `lib/utils/app_config.dart` | Added `AppConfig.getDeviceId()` for hardware ID persistence. |
| `lib/database/db_helper.dart` | Upgraded SQLite schema to version 3 with `device_id` column. |
| `lib/models/grading_log.dart` | Added `deviceId` property to local data model. |
| `lib/services/sync_service.dart` | Included `device_id` in multipart sync requests. |
| `lib/views/scan_result_screen.dart` | Removed delivery batch dependency; automatically attaches persistent device ID to every scan. |
| `lib/views/settings_screen.dart` | Displays the phone's unique `_deviceId` dynamically. |
