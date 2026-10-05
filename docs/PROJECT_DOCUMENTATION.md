# Verithrive Mobile Application Documentation

## Overview

This is a Flutter-based mobile application for Verithrive, designed to connect end-users with fitness, wellness, and nutrition professionals. The app supports two user roles: **End User** and **Professional**.

### Application Version
- **Version:** 1.0.0+4
- **Flutter SDK:** >=3.4.0 <4.0.0
- **Last Updated:** 2026-06-23

## Project Structure

The project is organized into the following main directories:

```
verithrive_dev/
├── lib/
│   ├── api/                # API client and service definitions
│   ├── common/             # Shared components and utilities
│   ├── core/               # Core widgets and common components
│   ├── enduser/            # End user application code
│   ├── professional/       # Professional application code
│   ├── routes/             # Route definitions
│   ├── select_user/        # User role selection screen
│   ├── services/           # Core services (analytics, notifications, etc.)
│   ├── theme/              # App theming and styling
│   ├── utils/              # Utility functions and helpers
│   ├── widgets/            # Reusable custom widgets
│   ├── models/             # Shared data models
│   └── main.dart           # Application entry point
├── assets/                 # Images, fonts, and other assets
│   ├── images/             # Image assets
│   └── fonts/              # Custom fonts (Poppins, Rubik)
├── android/                # Android platform code
├── ios/                    # iOS platform code
└── pubspec.yaml            # Dependencies and configuration
```

## Application Features

### End User Features

The end-user application provides the following functionality:

#### Authentication & Onboarding
- **Login/Registration:** Email-based authentication with OTP verification
- **Social Auth:** Google Sign-In and Apple Sign-In integration
- **Forgot Password:** Password recovery flow
- **Onboarding:** User onboarding and introduction screens

#### Home & Discovery
- **Home Screen:** Dynamic profession categories (Wellness, Fitness, Food & Nutrition)
- **Professional Discovery:** Browse and filter professionals by category
- **Search & Filter:** Advanced filtering options for finding professionals
- **Therapy List:** View available therapy services

#### Booking & Appointments
- **Appointment Booking:** Schedule appointments with professionals
- **Cart System:** Add services to cart for booking
- **Payment Integration:** Secure payment processing
- **Transaction Summary:** View booking and payment history

#### Consultation & Messaging
- **Real-time Chat:** In-app messaging with professionals
- **Consultation Management:** Manage ongoing consultations
- **Socket Integration:** Real-time message updates via Socket.io

#### Profile & Account
- **Profile Management:** Update personal information
- **Address Management:** Manage multiple addresses with map selection
- **Goal Setting:** Set fitness and nutrition goals
- **Notification Preferences:** Manage notification settings

#### Additional Features
- **Notifications:** Push notifications for appointments and messages
- **Location Services:** Location-based services and address selection
- **Camera & Gallery:** Image picker for profile photos and documents
- **HTML Content:** Display rich HTML content (terms, policies)

### Professional Features

The professional application provides the following functionality:

#### Authentication
- **Login/Registration:** Professional account creation and login
- **Email Verification:** Email verification flow
- **Password Recovery:** Forgot password functionality
- **Onboarding:** Professional onboarding process

#### Profile Management
- **Profile Wizard:** Step-by-step profile setup
- **Personal Details:** Professional information and credentials
- **Terms & Conditions:** Acceptance of service terms
- **Address Management:** Service area selection with map

#### Subscription & Payments
- **Subscription Plans:** View and select subscription plans
- **Payment Methods:** Manage payment methods
- **Stripe Integration:** Stripe account creation for payments
- **Payment Processing:** Handle payment transactions

#### Dashboard & Operations
- **Home Dashboard:** Overview of appointments and activities
- **Notifications:** Receive booking and message notifications
- **Appointment Management:** View and manage client appointments

## Technical Architecture

### State Management
- **GetX Framework:** Used for state management, dependency injection, and routing
- **Reactive Programming:** Obx and GetX controllers for reactive state updates

### API & Networking
- **Dio:** HTTP client for API requests
- **API Service Layer:** Centralized API service in `lib/api/user_api_service.dart`
- **Response Handling:** Standardized API response handling in `lib/api/api_response.dart`

### Third-Party Integrations

#### Firebase Services
- **Firebase Core:** Firebase initialization and configuration
- **Firebase Analytics:** User behavior tracking and analytics
- **Firebase Messaging:** Push notifications for both user roles
- **Firebase Token Service:** Token management for push notifications

#### Authentication Services
- **Google Sign-In:** OAuth authentication via Google
- **Apple Sign-In:** OAuth authentication via Apple
- **Social Auth Service:** Unified social authentication handling

#### Location Services
- **Google Maps Flutter:** Interactive map display
- **Geocoding:** Address to coordinates conversion
- **Google Places Flutter:** Place autocomplete and search
- **Geolocator:** Current location detection

#### Real-time Features
- **Socket.io Client:** Real-time messaging and updates
- **Connectivity Plus:** Network connectivity monitoring

#### Media & File Handling
- **Image Picker:** Camera and gallery image selection
- **File Picker:** Document and file selection
- **Image Cropper:** Image editing and cropping
- **Permission Handler:** Runtime permission management

#### UI Components
- **Flutter SVG:** SVG image rendering
- **Carousel Slider:** Image and content carousels
- **Dropdown Button2:** Enhanced dropdown components
- **Flutter HTML:** HTML content rendering
- **WebView Flutter:** In-app web content display

#### Utilities
- **Sizer:** Responsive screen sizing
- **Flutter ScreenUtil:** Screen adaptation utilities
- **Intl:** Internationalization and date formatting
- **Shared Preferences:** Local data persistence
- **Logger:** Logging and debugging
- **Device Info Plus:** Device information retrieval
- **Package Info Plus:** App version and build information
- **Path Provider:** File system path access
- **Flutter Toast:** Toast notifications
- **Share Plus:** Content sharing
- **URL Launcher:** External URL handling
- **Flutter Timezone:** Timezone detection

### Core Services

Located in `lib/services/`:

- **Analytics Service:** Firebase Analytics integration for event tracking
- **Camera Storage Permission Service:** Camera and storage permission handling
- **Connectivity Service:** Network connectivity monitoring
- **Firebase Token Service:** Firebase token management
- **Foreground Notification Service:** Foreground notification handling
- **Location Permission Service:** Location permission management
- **Notification Permission Service:** Notification permission handling
- **Notification Service:** Local notification management
- **Social Auth Service:** Social authentication implementation
- **Socket Service:** Socket.io connection management
- **Storage Service:** Local storage operations

### UI/UX Features

#### Theming
- **Custom Theme:** App-wide theming in `lib/theme/`
- **Color System:** Centralized color definitions
- **Typography:** Poppins and Rubik font families with multiple weights

#### Responsive Design
- **Screen Adaptation:** Responsive design using ScreenUtil and Sizer
- **Device Support:** Support for various screen sizes and orientations

#### Custom Widgets
- **Common Widgets:** Reusable UI components in `lib/widgets/`
- **Core Widgets:** Core UI components in `lib/core/`
- **End User Widgets:** End-user specific widgets in `lib/enduser/widgets/`

## Environment Configuration

### Flavor Configuration
The app supports multiple environments (flavors). Configuration is located in:
- `lib/enduser/flavors/` - End-user environment-specific configuration

### Required Configuration Files

#### Android
- `android/app/google-services.json` - Firebase configuration (not in version control)
- `android/app/build.gradle.kts` - Signing configuration for release builds

#### iOS
- `ios/Runner/GoogleService-Info.plist` - Firebase configuration (not in version control)

**Note:** Sensitive configuration files are not committed to version control. Contact the project admin to obtain these files.

## Prerequisites

To run this project locally, you'll need the following installed:

1. **Flutter SDK (>=3.4.0 <4.0.0)**
   - [Installation guide](https://docs.flutter.dev/get-started/install)
   - Verify installation with `flutter doctor`
   - **Important:** The project requires Flutter SDK 3.4.0 or higher but less than 4.0.0

2. **IDE**
   - Android Studio / VS Code with Flutter plugins
   - Recommended: VS Code with Flutter and Dart extensions

3. **Android Studio (for Android development)**
   - With Android SDK and appropriate emulator
   - Required for Android builds even if using VS Code

4. **Xcode (for iOS development, macOS only)**
   - With iOS simulator
   - Required for iOS builds

5. **Git**
   - For version control operations

## How to Run Locally

### 1. Clone the Repository

```bash
git clone <repository-url>
cd VerithriveMerge
```

### 2. Install Dependencies

In the project root directory, run:
```bash
flutter pub get
```

### 3. Set Up Firebase

Ensure you have the correct Firebase configuration files in place:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

**Note:** These files are not in version control. Contact the project admin to obtain them.

### 4. Configure Environment

Check environment-specific configuration in:
- `lib/enduser/flavors/` for end-user app flavors
- Update any environment variables as needed

### 5. Run the Application

#### Android

```bash
flutter run
```

Or specify a device:
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>
```

#### iOS

```bash
flutter run
```

Or specify a device:
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>
```

### 6. Hot Reload/Hot Restart

During development:
- Press `r` in the terminal for hot reload
- Press `R` for hot restart
- Use `q` to quit

## Build Instructions

### Android

#### Debug Build
```bash
flutter build apk --debug
```

#### Release Build
```bash
flutter build apk --release
```

The resulting APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

#### App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

The resulting AAB will be located at: `build/app/outputs/bundle/release/app-release.aab`

### iOS

#### Debug Build
```bash
flutter build ios --debug
```

#### Release Build
```bash
flutter build ios --release
```

#### Archive for Distribution

To generate an IPA file for distribution, use Xcode:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your target device
3. Go to Product -> Archive
4. Follow the distribution steps in Xcode

Alternatively, use command line:
```bash
flutter build ios --release
```

Then open in Xcode to archive and distribute.

## Testing

### Run Unit Tests
```bash
flutter test
```

### Run Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

## Code Quality

### Analyze Code
```bash
flutter analyze
```

### Format Code
```bash
flutter format .
```

## Project Dependencies

### Core Dependencies

See `pubspec.yaml` for a complete list of dependencies. Key dependencies include:

#### State Management & Navigation
- `get: ^4.7.3` - State management, dependency injection, and routing

#### Networking
- `dio: ^5.9.0` - HTTP client for API requests

#### UI & Responsive Design
- `sizer: ^3.1.3` - Responsive screen sizing
- `flutter_screenutil: ^5.5.3+2` - Screen adaptation utilities
- `flutter_svg: ^latest` - SVG image rendering
- `carousel_slider: ^5.0.0` - Image and content carousels
- `dropdown_button2: ^2.3.9` - Enhanced dropdown components

#### Firebase
- `firebase_core: ^3.6.0` - Firebase core
- `firebase_analytics: ^11.3.0` - Analytics
- `firebase_messaging: ^15.0.0` - Push notifications

#### Authentication
- `google_sign_in: ^6.2.1` - Google authentication
- `sign_in_with_apple: ^6.1.3` - Apple authentication

#### Location Services
- `google_maps_flutter: ^2.5.0` - Google Maps integration
- `geocoding: ^3.0.0` - Address to coordinates conversion
- `google_places_flutter: ^2.0.0` - Place autocomplete
- `geolocator: ^12.0.0` - Current location detection

#### Media & Files
- `image_picker: ^1.0.2` - Camera and gallery image selection
- `file_picker: ^8.0.0` - Document and file selection
- `image_cropper: ^11.0.0` - Image editing and cropping

#### Permissions
- `permission_handler: ^11.0.0` - Runtime permission management

#### Real-time
- `socket_io_client: ^2.0.3+1` - Socket.io client
- `connectivity_plus: ^6.0.5` - Network connectivity

#### Notifications
- `flutter_local_notifications: ^17.2.3` - Local notifications

#### Utilities
- `shared_preferences: ^2.5.3` - Local data persistence
- `logger: ^1.1.0` - Logging
- `device_info_plus: ^12.3.0` - Device information
- `package_info_plus: ^4.0.2` - App version info
- `path_provider: ^2.1.5` - File system paths
- `fluttertoast: ^9.0.0` - Toast notifications
- `intl: ^0.18.0` - Internationalization
- `flutter_timezone: ^4.1.1` - Timezone detection

#### Web & Content
- `webview_flutter: ^4.13.1` - In-app web content
- `flutter_html: ^3.0.0-beta.2` - HTML content rendering

#### Sharing
- `share_plus: ^10.0.0` - Content sharing
- `url_launcher: ^6.3.0` - External URL handling

### Dev Dependencies
- `flutter_test` - Testing framework
- `flutter_lints: ^4.0.0` - Lint rules
- `flutter_launcher_icons: ^0.14.0` - App icon generation

## Local Development Tips

### Clear Cache and Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

### Reset Simulator/Emulator Data
- **Android:** Wipe data from AVD manager
- **iOS:** Erase all content and settings from Simulator

### Debugging
- Use `print()` statements for quick debugging
- Use Flutter DevTools for advanced debugging
- Run `flutter attach` to connect to a running app

### Common Development Commands
```bash
# Check Flutter environment
flutter doctor

# Upgrade Flutter SDK
flutter upgrade

# Upgrade dependencies
flutter pub upgrade

# Check for outdated dependencies
flutter pub outdated

# Run with specific flavor (if configured)
flutter run --flavor <flavor-name>
```

## Deployment

### Server Deployment Guidelines

This section provides guidelines for deploying builds to a server or distribution platform.

### General Steps

1. **Build the App**
   - Follow build instructions above for Android/iOS
   - Ensure you're building the release version

2. **Sign the App**
   - **Android:** Configure signing in `android/app/build.gradle.kts`
   - **iOS:** Use Xcode for code signing and provisioning profiles

3. **Test the Build**
   - Test the release build on physical devices
   - Verify all features work correctly
   - Check push notifications and deep links

4. **Distribute**
   - **Android:** Upload to Google Play Console or internal distribution server
   - **iOS:** Upload to App Store Connect or TestFlight

### Android Signing

1. Generate a keystore file (if not already created)
2. Configure signing in `android/app/build.gradle.kts`
3. Keep the keystore file and passwords secure
4. Never commit keystore files to version control

### iOS Signing

1. Create an Apple Developer account
2. Configure provisioning profiles in Apple Developer portal
3. Use Xcode to configure code signing
4. Test on TestFlight before App Store release

### Important Security Notes

- Never commit sensitive files (keys, secrets, keystore files)
- Use environment variables or secure configuration management for production
- Keep Firebase and API keys secure
- Use different configurations for development, staging, and production
- Regularly update dependencies to security patches

## Troubleshooting

### Common Issues

#### 1. Flutter SDK Version Mismatch
**Error:** `The current Dart SDK version is 3.4.3. Because verithrive_dev depends on webview_flutter >=4.9.0 which requires SDK version >=3.5.0 <4.0.0`

**Solution:**
- Upgrade Flutter SDK to version 3.5.0 or higher
```bash
flutter upgrade
```

#### 2. Gradle Sync Failed
**Error:** Gradle sync fails in Android Studio

**Solution:**
- Check Android SDK path in `local.properties`
- Run `flutter doctor` to verify dependencies
- Delete `.gradle` folder in project root and retry
- Ensure Android SDK is properly installed

#### 3. CocoaPods Issues on iOS
**Error:** Pod install fails or dependency issues

**Solution:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

#### 4. Build Errors Related to Missing Files
**Error:** Missing configuration files

**Solution:**
- Ensure you have all required configuration files from the project admin
- Check `android/app/google-services.json` is present
- Check `ios/Runner/GoogleService-Info.plist` is present

#### 5. Firebase Configuration Issues
**Error:** Firebase initialization fails

**Solution:**
- Verify Firebase configuration files are correct
- Check Firebase project settings
- Ensure package name/bundle ID matches Firebase configuration
- Re-download configuration files from Firebase console

#### 6. Permission Errors
**Error:** Runtime permission requests fail

**Solution:**
- Check permission declarations in `android/app/src/main/AndroidManifest.xml`
- Check permission declarations in `ios/Runner/Info.plist`
- Ensure permission handler is properly configured
- Test on physical device (emulators may have permission limitations)

#### 7. Network Request Failures
**Error:** API requests fail with network errors

**Solution:**
- Check internet connectivity
- Verify API base URL is correct
- Check if SSL certificate is valid (for HTTPS)
- For HTTP requests, ensure network security config allows cleartext traffic (Android)
- Check firewall/proxy settings

#### 8. Image Loading Issues
**Error:** Images fail to load from network

**Solution:**
- Check image URLs are accessible
- Verify HTTPS/HTTP protocol compatibility
- Check image format is supported
- For SVG files, ensure flutter_svg is properly configured
- Check network security settings for HTTP resources

#### 9. Hot Reload Not Working
**Error:** Changes not reflected with hot reload

**Solution:**
- Try hot restart instead (press `R`)
- If that fails, stop and restart the app
- Some changes require full app restart (e.g., adding new dependencies)
- Check for syntax errors in your code

#### 10. App Crashes on Startup
**Error:** App crashes immediately after launch

**Solution:**
- Check Firebase initialization
- Verify all required configuration files are present
- Check for missing native dependencies
- Review crash logs in Android Logcat or Xcode console
- Ensure all async operations are properly handled

### Get Help

If you encounter issues not covered here:
1. Check [Flutter documentation](https://docs.flutter.dev/)
2. Review the project's Git history for recent changes
3. Check package documentation on pub.dev
4. Contact the development team
5. Review error logs carefully for specific error messages

## Architecture Patterns

### MVVM Pattern
The application follows the MVVM (Model-View-ViewModel) pattern:
- **Model:** Data classes in `lib/models/` and feature-specific models
- **View:** UI screens in `lib/enduser/screens/` and `lib/professional/`
- **ViewModel:** Controllers in `lib/enduser/core/` and feature-specific controllers

### Service Layer
Centralized services in `lib/services/` provide:
- Analytics tracking
- Permission management
- Notification handling
- Socket connections
- Social authentication
- Storage operations

### API Layer
The API layer in `lib/api/` provides:
- Centralized HTTP client (Dio)
- API response handling
- Service-specific API methods
- Error handling and retry logic

### Dependency Injection
GetX is used for dependency injection:
- Controllers are registered with GetX
- Services are singleton instances
- Dependencies are injected via Get.find()

## Code Organization Best Practices

### File Naming
- Use camelCase for Dart files: `homeScreen.dart`
- Use snake_case for directories: `home_screen/`
- Keep file names descriptive and concise

### Folder Structure
- Group related functionality in folders
- Separate concerns (screens, controllers, models, services)
- Keep shared utilities in common folders

### Code Style
- Follow Dart style guide
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small

### State Management
- Use GetX controllers for state management
- Use Obx for reactive UI updates
- Keep controllers focused on specific features
- Dispose controllers properly when not needed

## Security Considerations

### API Keys and Secrets
- Never commit API keys to version control
- Use environment variables for sensitive data
- Use Firebase Remote Config for runtime configuration
- Restrict API keys in Firebase console

### Data Storage
- Use secure storage for sensitive user data
- Encrypt sensitive data when storing locally
- Clear sensitive data when user logs out
- Use HTTPS for all network requests

### Authentication
- Implement proper session management
- Use secure token storage
- Implement token refresh logic
- Handle authentication failures gracefully

### Permissions
- Request permissions only when needed
- Explain why permissions are needed
- Handle permission denials gracefully
- Provide fallback functionality when permissions are denied

## Performance Optimization

### Build Optimization
- Use release builds for performance testing
- Enable code shrinking for Android
- Use ProGuard/R8 for Android
- Optimize assets and images

### Runtime Optimization
- Use const constructors where possible
- Avoid unnecessary rebuilds with GetX
- Use lazy loading for lists
- Implement pagination for large datasets
- Cache API responses appropriately

### Memory Management
- Dispose controllers properly
- Close streams and subscriptions
- Use efficient image loading
- Avoid memory leaks with proper cleanup

## Accessibility

### Visual Accessibility
- Use appropriate text sizes
- Provide sufficient color contrast
- Support dynamic type scaling
- Use semantic labels for images

### Screen Reader Support
- Add semantic labels for important widgets
- Use meaningful widget descriptions
- Test with TalkBack (Android) and VoiceOver (iOS)

### Touch Targets
- Ensure touch targets are at least 48x48 pixels
- Provide adequate spacing between interactive elements
- Support keyboard navigation where appropriate

## Contributing Guidelines

### Code Review Process
1. Create a feature branch from main/master
2. Make changes and test thoroughly
3. Ensure code follows project style guidelines
4. Update documentation if needed
5. Submit pull request for review
6. Address review feedback
7. Merge after approval

### Commit Messages
- Use clear, descriptive commit messages
- Follow conventional commit format if applicable
- Reference related issues if any

### Testing
- Write unit tests for business logic
- Test UI changes on multiple screen sizes
- Test on both Android and iOS if applicable
- Verify no regressions in existing functionality

## License

(Add license information here)

## Support and Contact

For questions or support regarding this project:
- Contact the development team
- Review project documentation
- Check issue tracker for known issues

---

**Last Updated:** 2026-06-23
**Document Version:** 2.0
