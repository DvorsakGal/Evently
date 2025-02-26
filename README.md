# Evently 📱

Evently is a mobile application built with Flutter that enables users to effortlessly organize group events, such as trips, team-building activities, celebrations, or day outings. The app is designed for friends, families, teams, and students who want a hassle-free way to coordinate activities and ensure all members stay in sync.

## Features
- **Create and Customize Events 🎉** – Easily set up events with location, time, and reservations.
- **Send Invitations 📩** – Invite friends and track attendance confirmations.
- **Manage Task Lists 📋** – Organize to-do lists for smooth event planning.
- **Track Attendance ✅** – View who has confirmed participation.
- **Weather Monitoring 🌤️** – Get weather updates for the event location.
- **Bulletin Board 💬** – A chat-like feature for event participants to share updates and messages (Not yet logically implemented).

## User Authentication 🔑
Evently uses Firebase Authentication for user registration and login. Upon signing up, each user is assigned a random color, which serves as their profile indicator. This color is used as a border on posts made in the bulletin board, providing a simple and effective visual identity system.

## Minimal UI for a Seamless UX
We focused on a clean and minimalistic user interface, ensuring that functionalities are intuitive and easy to navigate. The goal is to keep the event organization process straightforward without unnecessary complexity.

## Demo▶️
A video demo of Evently is included in the GitHub repository. You can find it in the PowerPoint presentation file: **Evently.pptx**. </br>
Screenshots and short  instructions can be found in **Evently_vodic.pdf**.

## Technologies Used ⚙️🔥☁️
- **Flutter** – Cross-platform mobile development
- **Firebase Authentication** – User login and registration
- **Firebase Core** – Integration with Firebase services
- **Cloud Firestore** – Database for storing event details
- **Weather Package** – Fetching weather updates
- **Dio** – HTTP client for API requests
- **Intl** – Internationalization support
- **Cupertino Icons** – iOS-style icons

## Installation
1. Clone this repository:
   ```sh
   git clone https://github.com/your-repo/Evently.git

2. Navigate to the project directory:
    ```sh
   cd Evently

3. Install dependencies:
   ```sh
   flutter pub get

4. Run the application:
   ```sh
   flutter run

## Test user
In case you don't want to create your own user, you can use this test user: </br>
email: user1@gmail.com
password: password1
