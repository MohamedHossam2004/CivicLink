CivicLink is a mobile application designed to foster seamless communication and interaction between citizens and their local government. The platform aims to organize and enhance civic life by providing a centralized hub for announcements, community feedback, problem reporting, and local information.
It features three distinct roles: Citizens, a single Government Admin, and Advertisers, each with a tailored set of functionalities.

⸻

Key Features

For Citizens 👨‍👩‍👧‍👦
	•	Stay Informed: View a live feed of government announcements, such as maintenance schedules or local news, complete with any attached images or documents.
	•	Voice Your Opinion: Participate in anonymous government polls on community matters, with the option to add public or anonymous comments to provide context for your vote. You can also view the results of completed polls to see the community’s collective opinion.
	•	Report Issues: Easily report neighborhood problems like a broken streetlight by providing a description, uploading photos, and pinpointing the exact location on a map. You can also track the status of your submitted reports.
	•	Direct Communication: Send private messages directly to the government for confidential inquiries or feedback.
	•	Community Engagement: Discover and sign up for local volunteer opportunities to contribute to your community and track your participation history.
	•	Local Discovery: View approved advertisements from local businesses to stay aware of relevant services and offers.
	•	Essential Contacts: Quickly access a list of important emergency and official phone numbers.

For the Government Admin 🏛️
	•	Secure Management: Log in to a single, secure admin account to manage all app content and functionalities.
	•	Broadcast Information: Create, edit, delete, and categorize announcements to effectively communicate with citizens.
	•	Gather Feedback: Create polls with specific questions and timeframes, and analyze real-time results and comments to gauge public opinion.
	•	Manage Communications: View and respond to private messages from citizens and manage all incoming problem reports. This includes updating the status of a report from “Received” to “Resolved”.
	•	Content Control: Review, approve, or reject advertisements submitted by businesses to ensure they meet community standards.
	•	Organize Community Efforts: Post and manage volunteer tasks, view lists of participants, and mark tasks as complete.

For Advertisers 📢
	•	Promote Your Business: Register for an account to create and submit advertisements, including text and images, for government approval.
	•	Track Your Ads: View the status of your submissions (e.g., Pending, Approved, Rejected) and receive notifications when the status changes.
	•	Manage Your Content: Edit your ads before they are approved or delete them from the system.

⸻

Technical Features
	•	Backend: The application is powered by Firebase for a real-time, online database to dynamically store and retrieve all data.
	•	Authentication: Secure, role-based user authentication is implemented for all three user types.
	•	Push Notifications: The system uses push notifications to alert users in a timely manner about important updates, such as new announcements, poll results, or status changes on their reports.
	•	Map Integration: Leverages map services to allow citizens to accurately pinpoint the location of a problem they are reporting.
	•	Intuitive UI/UX: Designed with a focus on a high-quality, user-friendly, and visually appealing interface to ensure a positive user experience. The app features intuitive navigation like a bottom navigation bar or tabs.
	•	Error Handling: The app gracefully handles potential issues like network connectivity problems or invalid user input, providing clear feedback to the user.

⸻

✨ Bonus Feature: AI Moderation
	•	The application includes an AI-powered system to automatically detect and flag potentially offensive comments in both Arabic and English within announcements and polls. The admin can configure this system to automatically delete or prevent the posting of such comments to maintain a respectful environment.

⸻

🚀 Getting Started

To get a local copy up and running, follow these simple steps.

Prerequisites
	•	Flutter SDK
	•	An editor like VS Code or Android Studio
	•	A configured Firebase project

Installation
	•	Clone the repo
git clone https://github.com/MohamedHossam2004/CivicLink.git
	•	Navigate to the project directory
cd CivicLink
	•	Install packages
flutter pub get
	•	Run the app
flutter run

⸻

Built With
	•	Flutter – The UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.
	•	Firebase – The backend platform for building web and mobile applications.
	•	Figma – Used for the initial UI/UX design process.