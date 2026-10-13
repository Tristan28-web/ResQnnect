# 🚀 ResQnnect (GeoSafe) — Project Checkpoint & Transition Guide

> **Generated on:** 2026-10-13  
> **Repository:** `https://github.com/Tristan28-web/ResQnnect.git`  
> **Active Branch:** `main`  
> **Latest Git Commit:** `d5f518e` — *feat(incident): replace pending/confirm/responder flows with automated 15-day Active/Closed lifecycle*  
> **Live PWA Hosting:** [https://resqnnect-3b59e.web.app](https://resqnnect-3b59e.web.app) / [https://resqnnect-3b59e.firebaseapp.com](https://resqnnect-3b59e.firebaseapp.com)  
> **Release APK Artifact:** `build\app\outputs\flutter-apk\app-release.apk` (56.7 MB)

---

## 📌 1. Executive Summary & Purpose

**ResQnnect (branded in-app as GeoSafe)** is a disaster risk reduction, GIS mapping, and emergency incident monitoring platform developed for Catanduanes Local Government Units (LGUs) and its residents. 

The application facilitates:
1. Real-time GIS incident reporting with photo evidence and geolocation pins.
2. AI-driven predictive disaster analytics and comparative barangay risk assessment.
3. Rapid SOS emergency broadcasting with device hardware triggers.
4. LGU-to-citizen broadcast advisories featuring strobe/flashlight alerts.
5. Automated 15-day incident lifecycle management without manual responder overhead.

---

## 🛠️ 2. Tech Stack & Environment

* **Framework:** Flutter (3.x / Dart 3.x)
* **Backend & Cloud:** Firebase (`resqnnect-3b59e`)
  * Firebase Authentication (Email/Password, Google Sign-In)
  * Cloud Firestore (Real-time NoSQL database)
  * Firebase Hosting (Single-page PWA deployment)
* **GIS & Mapping:** `google_maps_flutter` (2.15.0), `flutter_map` (7.0.2), `geolocator`
* **Device Hardware & Media:** `torch_light` (1.1.0), `image_picker` (1.1.2)
* **State Management & Architecture:** Provider (6.1.5+1), StreamBuilders, RxDart
* **Platforms Supported:**
  * **Android Native App (APK):** Full access to hardware flashlight strobes and accessibility services.
  * **Progressive Web App (PWA):** Fully responsive web version running on iOS Safari, Android Chrome, and Desktop browsers.

---

## 👥 3. User Roles & Architecture

The application operates strictly under **two (2) active roles**:

1. **Citizen (`citizen`)**:
   * Reports incidents with photos, location pins, and category selection.
   * Views their own submitted reports, live barangay updates, and safety advisories.
   * Sends emergency SOS alerts with auto-detected GPS coordinates.
   * Receives real-time LGU broadcast advisories with camera flashlight strobe pulses.
2. **LGU Admin (`admin`)**:
   * Accesses the Admin Command Dashboard with real-time incident metrics.
   * Reviews incident reports with interactive photo zoom dialogs.
   * Views the Gemini AI Predictive Analysis barangay risk ranking bar charts.
   * Broadcasts official emergency alerts to all citizens.
   * Verifies new resident accounts via ID card verification.

> ⚠️ **CRITICAL NOTE ON RESPONDER ROLE:**
> The previous **"Responder"** role and manual status change workflow (`Pending`, `Confirmed`, `Dispatched`, `Responding`, `Resolved`) have been **completely deprecated and removed**. All incident reports now operate exclusively under the automated **15-day Active/Closed lifecycle**.

---

## ⚙️ 4. Core Features & Recent Key Implementations

### A. Automated 15-Day Incident Lifecycle Policy
* **Behavior:** Every incident reported starts immediately with status **`active`**.
* **Auto-Close:** If `DateTime.now().difference(timestamp).inDays >= 15`, the incident is automatically evaluated and synced as **`closed`**.
* **Removed:** All manual "Update Status" radio dialogs, responder action buttons, and "Pending / Confirm" text badges.
* **UI Representation:** Badges show `ACTIVE (14D LEFT)` while open, and `CLOSED` once the 15-day limit expires.
* **Files:** `lib/models/incident_model.dart`, `lib/services/firestore_service.dart`, `lib/screens/incident_monitoring_screen.dart`, `lib/screens/citizen_dashboard.dart`, `lib/screens/admin_dashboard.dart`.

### B. Cross-Platform Web PWA Compatibility & Photo Upload Fix
* **Issue Solved:** In Flutter Web, importing `dart:io` and calling `File(path)` caused `Unsupported operation: _Namespace` crashes.
* **Solution:** Replaced `dart:io` `File` with cross-platform memory buffers (`Uint8List` from `dart:typed_data` and `Image.memory`).
* **Firestore 1MB Document Limit Guard (`ImageUtils`):**
  * Cloud Firestore rejects document properties exceeding 1,048,487 bytes (`[cloud_firestore/invalid-argument] The value of property "image_base64" is longer than 1048487 bytes`).
  * Created `lib/core/image_utils.dart` which uses `ui.instantiateImageCodec` to downscale high-resolution phone camera photos to max 800px width/height and compress them into ~60KB–150KB Base64 strings.
* **Files:** `lib/core/image_utils.dart`, `lib/screens/report_screen.dart`, `lib/screens/report_hazard_screen.dart`, `lib/screens/global_map_screen.dart`, `lib/screens/edit_profile_screen.dart`.

### C. Predictive Analysis & Comparative Barangay Risk Graph
* **Feature:** Ranks all Catanduanes barangays by calculated risk scores.
* **UI Component:**
  * Top #1 Highest Risk Barangay hero badge (e.g., `Brgy. Concepcion`, `Brgy. Rawis`).
  * Comparative horizontal bar chart showing risk levels (e.g., High, Moderate, Low).
  * Sector-by-sector breakdown and AI Disaster Preparedness recommendations.
* **Files:** `lib/screens/predictive_analysis_screen.dart`, `lib/services/gemini_ai_service.dart`.

### D. Interactive Photo Evidence & Pinch-to-Zoom Modal
* **Component:** `lib/widgets/incident_detail_sheet.dart`.
* **Capabilities:** 
  * Parses embedded Base64 strings and network URLs seamlessly.
  * Tapping the image opens an interactive fullscreen pinch-to-zoom modal (`InteractiveViewer`).
  * Displays full incident metadata: Reference ID (e.g. `INC-001`), barangay, coordinates, timestamp, and remaining lifecycle days.
  * Includes a direct shortcut button: **"VIEW ON GIS MAP"**.

### E. Emergency Strobe Flashlight Alert System
* **Behavior:** When an Admin broadcasts an emergency alert via the LGU Broadcast modal (`/alerts` collection), the Citizen's phone LED flashlight triggers a **5-cycle rapid strobe pulse (SOS pattern)**.
* **Scope:** Reserved strictly for **Disaster Advisories / Alerts**. Routine incident reports do **not** flash the light to conserve battery and prevent panic.
* **Hardware Permissions:** Added `android.permission.FLASHLIGHT` and `android.hardware.camera.flash` in `android/app/src/main/AndroidManifest.xml`.
* **Platform Limitation:** Hardware torch control is exclusive to the **Android APK** (`app-release.apk`) because web browsers enforce sandbox security blocking direct camera LED access.
* **Files:** `lib/services/alert_notification_service.dart`, `lib/screens/citizen_dashboard.dart`, `android/app/src/main/AndroidManifest.xml`.

### F. Black Screen Back-Navigation Bug Resolution
* **Issue Solved:** Pressing the Android back button or app bar back arrow resulted in a blank/black screen when navigation history was empty.
* **Solution:** Implemented `AppNavigation.popOrHome(context, role)` and wrapped primary dashboard views in `PopScope(canPop: false)`.
* **Files:** `lib/core/navigation_utils.dart`.

### G. SOS Gesture Hardware Trigger (Accessibility Service)
* **Supported Gestures:** Triple Click Volume Up, Long Press Volume Down, Double Tap Screen.
* **Android Setup:** Configured via `Settings > Accessibility > GeoSafe (or GIS Accessibility Service)`.
* **Files:** `lib/screens/sos_gesture_settings_screen.dart`.

---

## 🗄️ 5. Firestore Database Schema Reference

### Collection: `incidents`
```json
{
  "incident_id": "1728512345678",
  "reference_id": "INC-5678",
  "user_id": "firebase_auth_uid",
  "incident_type": "Fire | Flood | Accident | Crime | Other",
  "barangay": "Brgy. Concepcion",
  "location": "Near Municipal Hall",
  "latitude": 13.52412,
  "longitude": 124.23841,
  "description": "Fallen power cables causing hazard.",
  "severity": "low | medium | high | critical",
  "status": "active | closed",
  "timestamp": "Timestamp",
  "image_base64": "data:image/jpeg;base64,... (safe <= 200KB)",
  "image_url": "https://...",
  "assigned_to": null,
  "resolution_notes": "Automatically closed after 15-day system lifecycle limit."
}
```

### Collection: `alerts` (Triggers Flashlight Strobe)
```json
{
  "alertId": "1728519999999",
  "title": "TYPHOON SIGNAL NO. 3 ADVISORY",
  "description": "Evacuate low-lying coastal areas immediately.",
  "disasterType": "Typhoon | Flood | Fire | Earthquake | Critical Advisory",
  "createdAt": "Timestamp"
}
```

### Collection: `users`
```json
{
  "uid": "firebase_auth_uid",
  "email": "citizen@resqnnect.com",
  "displayName": "Juan Dela Cruz",
  "role": "citizen | admin",
  "isVerified": true,
  "barangay": "San Roque",
  "phoneNumber": "09123456789",
  "idCardBase64": "..."
}
```

### Collection: `hazards`
```json
{
  "hazard_id": "1728510000000",
  "type": "roadHazard | naturalDisaster | other",
  "description": "Flooded street impassable for light vehicles.",
  "latitude": 13.52110,
  "longitude": 124.23110,
  "reported_by": "firebase_auth_uid",
  "status": "active",
  "image_base64": "...",
  "timestamp": "Timestamp"
}
```

---

## 📂 6. Codebase Directory Map

```text
ResQnnect/
├── android/
│   └── app/src/main/AndroidManifest.xml      # Camera, Flashlight, Location permissions
├── build/
│   ├── app/outputs/flutter-apk/              # Release APK (56.7 MB)
│   └── web/                                  # Compiled PWA assets
├── lib/
│   ├── core/
│   │   ├── constants.dart                    # AppColors (Retro mint/peach palette), collections
│   │   ├── image_utils.dart                  # Smart image downscaler (Firestore 1MB limit guard)
│   │   ├── localization.dart                 # Tagalog / English strings
│   │   └── navigation_utils.dart             # popOrHome & PopScope helper
│   ├── models/
│   │   ├── alert_model.dart                  # LGU emergency advisory model
│   │   ├── hazard_model.dart                 # Map hazard pins
│   │   ├── incident_model.dart               # Incidents with 15-day lifecycle rules
│   │   ├── user_model.dart                   # Resident & Admin profiles
│   │   └── sos_model.dart                    # Emergency SOS payloads
│   ├── screens/
│   │   ├── admin_dashboard.dart              # Admin control center (Broadcast banner, Incident list)
│   │   ├── admin_verification_screen.dart    # Resident ID approval UI
│   │   ├── citizen_dashboard.dart            # Resident portal (StreamProvider for alert torch strobe)
│   │   ├── global_map_screen.dart            # Full-screen interactive GIS map with pins
│   │   ├── incident_monitoring_screen.dart   # Filterable incident list (All, Active, Closed)
│   │   ├── predictive_analysis_screen.dart   # AI risk analysis & comparative bar chart
│   │   ├── report_screen.dart                # Main camera incident reporting screen
│   │   ├── report_hazard_screen.dart         # Quick road hazard reporting screen
│   │   ├── sos_screen.dart                   # One-tap panic SOS broadcast screen
│   │   └── sos_gesture_settings_screen.dart  # Hardware volume button SOS triggers
│   ├── services/
│   │   ├── alert_notification_service.dart   # TorchLight strobe pulser (5-cycle SOS strobe)
│   │   ├── auth_service.dart                 # Firebase Auth & Session state
│   │   ├── firestore_service.dart            # Firestore streams, queries, 15-day lifecycle sync
│   │   ├── gemini_ai_service.dart            # Generative predictive analytics & risk ranking
│   │   └── location_service.dart             # GPS Geolocation & Reverse Geocoding
│   ├── widgets/
│   │   ├── alert_card.dart                   # Emergency advisory broadcast card
│   │   ├── incident_detail_sheet.dart        # Full detail modal with interactive pinch-to-zoom
│   │   └── sos_hold_button.dart              # Long-press emergency trigger widget
│   └── main.dart                             # Entrypoint, MultiProvider setup, Firebase init
├── firebase.json                             # Hosting config for build/web
├── .firebaserc                               # Default Firebase project: resqnnect-3b59e
└── pubspec.yaml                              # Dependencies & assets
```

---

## 📜 7. Recent Git Commit Log

```text
d5f518e feat(incident): replace pending/confirm/responder flows with automated 15-day Active/Closed lifecycle
6d5b27d fix(firestore): enforce ImageUtils auto-resizing to prevent image_base64 > 1MB error
b4c6853 fix(web): resolve _Namespace error using cross-platform Uint8List for photo attachments
3e48bb3 feat(android): add FLASHLIGHT permission and camera flash feature
8911544 chore(hosting): configure default firebase project for PWA deployment
249fb2e feat(pwa): configure GeoSafe progressive web app metadata and build web release
e813580 feat(lifecycle): remove manual status dialog and implement automatic 15-day incident closure policy
25267d0 feat(incidents): add interactive photo viewer and full incident details modal across dashboards and maps
8b64099 feat(predictive-ai): add barangay risk comparative graph and highest-risk sector identification
e99024c fix: resolve black screen bug on back navigation across Admin and Citizen dashboards
```

---

## 💻 8. Build & Deployment Commands Cheatsheet

### Run Locally (Dev)
```powershell
flutter run -d chrome     # Run Web PWA
flutter run               # Run connected Android phone
```

### Build Android Release APK
```powershell
flutter build apk --release
# Outputs to: build\app\outputs\flutter-apk\app-release.apk
```

### Build & Deploy Progressive Web App (PWA)
```powershell
flutter build web --release
npx firebase-tools deploy --only hosting --project resqnnect-3b59e
# Live at: https://resqnnect-3b59e.web.app
```

---

## 🧭 9. Essential Guidelines for Claude AI Continuation

When continuing development with Claude, adhere to these technical contracts:

1. **Do NOT reintroduce Responders or Pending statuses**:
   The thesis scope has locked the incident workflow to an automated **15-day lifecycle** (`active` -> `closed`). Do not create buttons or dialogs allowing admins to manually toggle status to "In Progress" or "Resolved".
2. **Never use `dart:io` `File` in UI reporting screens**:
   Always use `Uint8List` and `Image.memory` to ensure full PWA and cross-platform compatibility without throwing `_Namespace` errors.
3. **Always route image uploads through `ImageUtils.processImageForFirestore`**:
   Never write raw camera photo Base64 directly to Firestore without passing through `ImageUtils` to avoid violating the 1,048,487 byte document property ceiling.
4. **Flashlight Strobe Trigger Boundary**:
   Keep `AlertNotificationService.flashAlert()` connected strictly to `/alerts` (Admin Broadcast Advisories). Do not connect it to general `/incidents` submissions.
5. **Preserve Retro Design Language**:
   The project uses custom retro neon/pastel UI colors (`AppColors.retroMint`, `AppColors.retroPeach`, `AppColors.retroLilac`, offset drop shadows `Offset(2, 2)` or `Offset(3, 3)` with solid borders). Ensure all new widgets conform to this aesthetic.
