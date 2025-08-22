# Gym Pro

A comprehensive Flutter-based gym management and fitness tracking application.

## Features

- **User Authentication**: Firebase Auth integration with email/password
- **Comprehensive User Profiles**: Complete profile management with personal information
  - Full name, username, email
  - Phone number, address
  - Gender selection (Male/Female/Other)
  - Date of birth picker
- **Profile Pictures**: Upload and manage profile photos with Firestore (FREE)
- **Real-time Updates**: Instant UI refresh after profile changes
- **Password Management**: Secure password change functionality
- **Privacy & Data Protection**: Comprehensive privacy features
  - Complete Privacy Policy (2000+ words)
  - Data settings and preferences management
  - User data export and deletion options
  - Transparency in data collection and usage
- **State Management**: GetX for reactive state management
- **Modern UI**: Material 3 design with Google Fonts
- **Firebase Integration**: Firestore database for data persistence
- **Image Upload**: Support for gallery and camera image selection (Base64 storage)## Project Structure

```
lib/
├─ app.dart                      # Main app configuration
├─ main.dart                     # App entry point
├─ firebase_options.dart         # Firebase configuration
├─ routes/
│  ├─ app_pages.dart            # Route definitions and pages
│  └─ app_routes.dart           # Route constants
├─ models/
│  └─ user_account.dart         # User data model
├─ services/
│  ├─ firebase_service.dart     # Firestore operations
│  └─ auth_service.dart         # Authentication operations
├─ controllers/
│  └─ auth_controller.dart      # Authentication state management
├─ views/
│  ├─ auth/
│  │  ├─ login_view.dart       # Login screen
│  │  └─ register_view.dart    # Registration screen
│  ├─ home/
│  │  └─ home_view.dart        # Home dashboard
│  └─ profile/
│     ├─ profile_view.dart     # User profile display
│     └─ edit_profile_view.dart # Profile editing
└─ widgets/
   ├─ app_text_field.dart      # Custom text input widget
   └─ app_button.dart          # Custom button widget

assets/
├─ images/                      # App images and logos
└─ fonts/                       # Custom fonts
```

## Dependencies

- **firebase_core**: Firebase initialization
- **firebase_auth**: Authentication services
- **cloud_firestore**: Database operations
- **get**: State management and navigation
- **intl**: Date/time formatting
- **google_fonts**: Typography

## Setup Instructions

### 1. Firebase Configuration

This project is configured for Firebase project ID: `gym-pro-2026`

To set up Firebase:

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Install Firebase CLI: `npm install -g firebase-tools`
3. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
4. Run `flutterfire configure` in the project root
5. Select your Firebase project and platforms
6. This will generate/update `firebase_options.dart` with your actual configuration

### 2. Firebase Services Setup

Enable these services in your Firebase project:

- **Authentication**: Enable Email/Password provider
- **Firestore Database**: Create database in test mode
- **Storage** (optional): For profile photos

### 3. Installation

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Authentication Flow

1. **Initial Route**: App checks authentication status
2. **Not Authenticated**: Redirects to Login screen
3. **Authenticated**: Redirects to Home screen
4. **Registration**: Creates user account and Firestore document
5. **Profile Management**: Users can view and edit their profiles

## Database Structure

### Users Collection (`users`)

```javascript
{
  id: "user_uid",
  email: "user@example.com",
  displayName: "User Name",
  photoURL: "https://...", // optional
  createdAt: timestamp,
  updatedAt: timestamp
}
```

## App Navigation

- `/` - Initial loading/auth check
- `/login` - Login screen
- `/register` - Registration screen
- `/home` - Home dashboard
- `/profile` - User profile view
- `/edit-profile` - Profile editing

## Development Notes

- Uses GetX for state management and routing
- Material 3 design system with custom theme
- Reactive UI with Obx widgets
- Error handling with user-friendly messages
- Form validation for all input fields

## Next Steps (Future Development)

- Workout tracking and planning
- Progress analytics and charts
- Nutrition tracking
- Social features and sharing
- Push notifications
- Offline data synchronization

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
