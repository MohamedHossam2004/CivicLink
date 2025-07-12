# CivicLink

CivicLink is a Flutter-powered mobile app that streamlines communication between citizens and their local government. It provides three roles—**Citizens**, a single **Government Admin**, and **Advertisers**—each with tailored functionality for announcements, polls, messaging, problem reporting, volunteering, and ad management. It also integrates Firebase and Google Cloud APIs to deliver real-time data, push notifications, maps, file uploads, and basic AI moderation.

---

## 🔑 Key Features

### For Citizens 👨‍👩‍👧‍👦
- **Announcements & Comments**  
  – View a live feed of government posts (text, images, PDFs)  
  – Comment publicly or anonymously  
- **Polls & Results**  
  – Vote once per poll (anonymous)  
  – Add optional comments (public or anonymous)  
  – View real-time and historic poll results  
- **Report Problems**  
  – Describe issues, upload photos, mark location on map  
  – Track status (Received → In Progress → Resolved)  
- **Private Messaging**  
  – Send and receive confidential messages to/from government  
- **Emergency & Official Contacts**  
  – One-tap calling of police, ambulance, municipality, etc.  
- **Volunteer Tasks & Calendar**  
  – Browse and sign up for local initiatives  
  – Track your participation history  
  – View public calendar of maintenance, events, volunteer dates  
- **Local Ads**  
  – See approved neighborhood advertisements  

### For Government Admin 🏛️
- **Single Secure Admin Account**  
  – Role-based login  
- **Announcements & File Uploads**  
  – Create, categorize, edit, delete (text + images/PDFs)  
- **Poll Management**  
  – Create polls with date ranges and options  
  – Monitor votes and comments in real time  
  – Archive or close polls  
- **Report & Message Handling**  
  – View details, images, and map locations of reports  
  – Update report status  
  – Read and reply to private citizen messages  
- **Contact & Ad Moderation**  
  – Manage emergency/official numbers  
  – Approve, reject, edit or remove advertiser submissions  
- **Volunteer Task Administration**  
  – Post tasks with descriptions, dates, locations  
  – Track sign-ups and mark completion  
- **Calendar Management**  
  – Add, edit, delete public calendar events  
- **AI-Powered Content Moderation**  
  – Automatically flag offensive comments (Arabic & English)  
  – Configure auto-delete or manual review  

### For Advertisers 📢
- **Account Registration & Login**  
- **Ad Creation & Submission**  
  – Upload text + images; await admin approval  
- **Submission Tracking**  
  – View status: Pending, Approved, Rejected  
  – Receive push notifications on status changes  
- **Edit or Delete Ads**  
  – Modify or remove ads pre- or post-approval  

---

## ⚙️ Technical Stack

- **Flutter** – Cross-platform UI  
- **Firebase**  
  - Realtime Database  
  - Firestore  
  - Authentication (email/password)  
  - Cloud Storage (images, PDFs)  
  - Cloud Messaging (push notifications)  
  - Cloud Functions (AI moderation)  
- **Google Cloud APIs**  
  - Maps SDK (location picker)  
  - Geocoding (reverse lookup)  
  - AI Vision / Natural Language (offensive-text detection)  
- **Environment & Secrets**  
  - API keys for Google services stored via `flutter_dotenv` or native config files  
- **State Management**  
  - Provider / Riverpod (depending on branch)  
- **CI/CD (optional)**  
  - GitHub Actions for build & tests  

---

## 🚀 Getting Started

### 📱 Download APK (Android Users)

For Android users who want to try the app without building from source:

**[Download CivicLink APK](https://drive.google.com/file/d/1ejaqHCRpiwxByPsZGMRcCwcw5yfwxOQU/view?usp=sharing)**

> **Note**: Replace `YOUR_GOOGLE_DRIVE_LINK_HERE` with your actual Google Drive link containing the APK file.

### Prerequisites

1. **Flutter SDK** (≥ 3.0)  
2. **Android Studio** or **VS Code** (+ Flutter & Dart plugins)  
3. **Git**  
4. **A Firebase project** with:  
   - Authentication enabled (Email/Password)  
   - Firestore or Realtime Database rules configured  
   - Cloud Storage bucket  
   - Cloud Messaging enabled  
   - (Optional) Cloud Functions deployed for AI moderation  
5. **Google Cloud project** enabled for Maps, Geocoding, and Vision/NLP APIs  
6. **API Keys** for all Google services  

---

## ⚙️ Configuration & Setup

1. **Clone the repo**  
   ```sh
   git clone https://github.com/MohamedHossam2004/CivicLink.git
   cd CivicLink
   ```
  
2.  **Create Environment File**: In the root of the project, create a `.env` file and populate it with your API keys.
    ```dotenv
    FIREBASE_API_KEY=...
    FIREBASE_APP_ID=...
    FIREBASE_MESSAGING_SENDER_ID=...
    FIREBASE_PROJECT_ID=...
    GOOGLE_MAPS_API_KEY=...
    GEOCODING_API_KEY=...
    VISION_API_KEY=...
    ```

3.  **Firebase Setup**:
    * Enable **Email/Password Authentication** in the Firebase console.
    * Set up **Firestore** or **Realtime Database**.
    * Configure **Cloud Storage** buckets.
    * Enable **Cloud Messaging**.
    * (Optional) Deploy **Cloud Functions** for features like content moderation.
    * Place the `google-services.json` file in the `android/app/` directory.
    * Place the `GoogleService-Info.plist` file in the `ios/Runner/` directory.

4.  **Google Cloud APIs**:
    * In the Google Cloud Platform console, enable the **Maps SDK**, **Geocoding API**, and **Vision API**.
    * Ensure the API keys are correctly referenced in `AndroidManifest.xml` (for Android) and `Info.plist` (for iOS), or loaded from your environment variables.

### 🧪 Installation & Running

1.  **Fetch Dependencies**:
    Open your terminal in the project root and run:
    ```sh
    flutter pub get
    ```

2.  **Run the App**:
    Execute the following command to run the application on an emulator or a connected device:
    ```sh
    flutter run
    ```

### 📦 Build for Release

To create a release build of the application, use the following commands:

* **Android**:
    ```sh
    flutter build apk
    ```

* **iOS** (requires Xcode):
    ```sh
    flutter build ios
    ```

---

## 📁 Project Structure

The source code is organized into the following directories within `lib/`:

* `main.dart`: The main entry point of the application.
* `models/`: Contains all the data model classes (e.g., `Announcement`, `Poll`, `Report`, `Ad`, `User`).
* `providers/`: Handles app-wide state management.
* `screens/`: Includes all the main screen UIs, typically organized by feature or user role.
* `services/`: Contains the business logic for interacting with Firebase and other APIs.
* `widgets/`: Stores reusable UI components (widgets) that are shared across multiple screens.
---

## 📝 License

This project is licensed under the MIT License.


