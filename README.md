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
   ```bash
   git clone https://github.com/MohamedHossam2004/CivicLink.git
   cd CivicLink