# Verithrive — Technology Stack & APIs

**Document version:** 1.0  
**Last updated:** 2026-07-16  
**App version:** 1.0.1+3

---

## 1. Core Platform

| Item | Value |
|------|-------|
| **Framework** | Flutter |
| **Language** | Dart (SDK `>=3.4.0 <4.0.0`) |
| **Package name** | `verithrive_dev` |
| **App version** | 1.0.1+3 |
| **Android application ID** | `com.app.verithrive` |
| **Android compileSdk / targetSdk** | 36 |
| **Platforms** | Android, iOS |

---

## 2. Technology Stack

### 2.1 State Management & Architecture

| Package | Version | Purpose |
|---------|---------|---------|
| `get` | ^4.7.3 | State management, dependency injection, routing |

### 2.2 Networking

| Package | Version | Purpose |
|---------|---------|---------|
| `dio` | ^5.9.0 | HTTP client for REST API calls |
| `socket_io_client` | ^2.0.3+1 | Real-time chat via Socket.IO |
| `connectivity_plus` | ^6.0.5 | Network connectivity monitoring |

### 2.3 Firebase

| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | ^3.6.0 | Firebase initialization |
| `firebase_analytics` | ^11.3.0 | User behaviour and event analytics |
| `firebase_messaging` | ^15.0.0 | Push notifications (FCM) |
| `flutter_local_notifications` | ^17.2.3 | Foreground and local notification display |

**Firebase project:** `verithrive---app---prod`  
**Config location:** `lib/common/firebase_config.dart`, `lib/enduser/core/utils/DefaultFirebaseOptions.dart`

### 2.4 Authentication

| Package | Version | Purpose |
|---------|---------|---------|
| `google_sign_in` | ^6.2.1 | Google OAuth |
| `sign_in_with_apple` | ^6.1.3 | Apple Sign-In |

Social tokens are exchanged with the Verithrive backend; the app stores a backend-issued Bearer token.

### 2.5 Location & Maps

| Package | Version | Purpose |
|---------|---------|---------|
| `google_maps_flutter` | ^2.5.0 | Interactive map display |
| `google_places_flutter` | ^2.0.0 | Address autocomplete (Google Places API) |
| `geocoding` | ^3.0.0 | Reverse geocoding (coordinates ↔ address) |
| `geolocator` | ^12.0.0 | Device GPS location |

### 2.6 Media & Files

| Package | Version | Purpose |
|---------|---------|---------|
| `image_picker` | ^1.0.2 | Camera and gallery access |
| `file_picker` | ^8.0.0 | Document selection |
| `image_cropper` | ^11.0.0 | Profile and document image cropping |
| `permission_handler` | ^11.0.0 | Runtime permission requests |
| `path_provider` | ^2.1.5 | File system paths |

### 2.7 UI & Content

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_screenutil` | ^5.5.3+2 | Screen adaptation (375×812 design baseline) |
| `sizer` | ^3.1.3 | Responsive sizing |
| `flutter_svg` | (open) | SVG rendering |
| `carousel_slider` | ^5.0.0 | Onboarding carousels |
| `dropdown_button2` | ^2.3.9 | Enhanced dropdowns |
| `flutter_html` | ^3.0.0-beta.2 | Render HTML content |
| `webview_flutter` | ^4.13.1 | Stripe Checkout, Stripe Connect, static pages |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

### 2.8 Utilities

| Package | Version | Purpose |
|---------|---------|---------|
| `shared_preferences` | ^2.5.3 | Local session and preference storage |
| `intl` | ^0.18.0 | Date, time, and number formatting |
| `logger` | ^1.1.0 | Debug logging |
| `device_info_plus` | ^12.3.0 | Device metadata for API headers |
| `package_info_plus` | ^4.0.2 | App version for API headers |
| `flutter_timezone` | ^4.1.1 | Timezone detection for API headers |
| `fluttertoast` | ^9.0.0 | Toast messages |
| `share_plus` | ^10.0.0 | Content sharing |
| `url_launcher` | ^6.3.0 | Open external URLs |

### 2.9 Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_test` | SDK | Unit and widget testing |
| `flutter_lints` | ^4.0.0 | Static analysis rules |
| `flutter_launcher_icons` | ^0.14.0 | App icon generation |

### 2.10 Typography

Custom fonts bundled in `assets/fonts/`:
- **Poppins** (weights 100–900)
- **Rubik** (weights 300–900)

---

## 3. Third-Party Services Summary

| Service | Integration type | Used for |
|---------|------------------|----------|
| **Verithrive Backend API** | REST + Socket.IO | All business logic, auth, bookings, chat, payments |
| **Firebase** | SDK | Analytics, push notifications |
| **Google Maps Platform** | SDK + API key | Map display, geocoding |
| **Google Places API** | SDK + API key | Address search and autocomplete |
| **Google Sign-In** | SDK | OAuth login (both roles) |
| **Apple Sign-In** | SDK | OAuth login (both roles) |
| **Stripe** | WebView (server-mediated) | Checkout for bookings and subscriptions; Connect for professional payouts |

### Not integrated

The following were searched for and **not found** in the codebase:

- Razorpay, PayPal SDK, Agora (video), Twilio, AWS SDK, OneSignal, Branch

---

## 4. Backend API — Environments

| Environment | REST (End User) | REST (Professional) | Socket.IO |
|-------------|-----------------|---------------------|-----------|
| **Production (active)** | `https://adminportal.verithrive.co.uk/api/api/v3/user/` | `https://adminportal.verithrive.co.uk/api/api/v3/professional/` | `https://adminportal.verithrive.co.uk` |
| Dev (commented) | `https://dev.verithrive.co.uk/api/api/v3/user/` | `https://dev.verithrive.co.uk/api/api/v3/professional/` | `https://dev.verithrive.co.uk` |
| Local (commented) | `http://192.168.0.14:4142/api/api/v3/user/` | `http://192.168.0.14:4142/api/v3/professional/` | `http://192.168.0.14:4142` |

**Source files:**
- End User: `lib/enduser/utils/api_services.dart`
- Professional: `lib/api/user_api_service.dart`

---

## 5. Common Request Headers (End User)

All end-user API requests include:

| Header | Description |
|--------|-------------|
| `Authorization` | `Bearer {access_token}` |
| `timezone` | Device timezone |
| `device_token` | FCM token |
| `device_id` | Unique device identifier |
| `device_type` | `android` or `ios` |
| `device_name` | Device model name |
| `os_version` | Operating system version |
| `app_version` | App version string |

---

## 6. End-User REST API Endpoints

Base URL: `https://adminportal.verithrive.co.uk/api/api/v3/user/`

### 6.1 Authentication & Account

| Endpoint | Method | Description |
|----------|--------|-------------|
| `register` | POST | User registration |
| `send-otp` | POST | Send OTP for verification |
| `verify-otp` | POST | Verify OTP |
| `verify-otp-and-register` | POST | Verify OTP and complete registration |
| `login` | POST | Email/password login |
| `social/signin` | POST | Google/Apple social login |
| `social/register-login` | POST | Social register and login |
| `logout` | POST | End session |
| `delete-account` | DELETE | Delete user account |
| `forgot-password/send-otp` | POST | Send password reset OTP |
| `forgot-password/verify-otp` | POST | Verify password reset OTP |
| `forgot-password/reset` | POST | Reset password |
| `change-password` | POST | Change password (authenticated) |

### 6.2 Profile

| Endpoint | Method | Description |
|----------|--------|-------------|
| `update-personal-details` | POST/PUT | Update profile |
| `get-personal-details` | GET | Fetch profile |
| `get-static-page` | GET | Terms, privacy policy (also served as WebView) |
| `notification` | POST | Update notification preferences |
| `update-device-token` | POST | Sync FCM token |

### 6.3 Discovery & Professionals

| Endpoint | Method | Description |
|----------|--------|-------------|
| `profession-types/all` | GET | Home screen categories |
| `professionals/list` | POST | Search and browse professionals |
| `professionals/details/{id}` | GET | Professional detail page |
| `professionals/save-unsave` | POST | Save/unsave a professional |
| `professionals/rate-review` | POST | Submit rating and review |
| `professionals/service-format-availability/details` | POST | Available timeslots |
| `get-services/all` | GET | Services catalog |

### 6.4 Bookings & Payments

| Endpoint | Method | Description |
|----------|--------|-------------|
| `validate-booking-window` | POST | Pre-booking validation |
| `create-booking` | POST | Create booking; returns Stripe Checkout URL |
| `update-booking` | PUT | Update/cart booking |
| `bookings/list` | POST | Booking history |
| `professional/platform-fee` | POST | Platform fee calculation |
| `add-cards` | POST | Save payment card |
| `edit-card/{id}` | PUT | Edit saved card |
| `get-cards-details` | GET | List saved cards |
| `delete-card/{id}` | DELETE | Remove saved card |
| `transactions/history` | POST | Transaction history |

### 6.5 Chat & Notifications

| Endpoint | Method | Description |
|----------|--------|-------------|
| `chat/inbox` | POST | Chat inbox list |
| `chat/room` | POST | Create or retrieve chat room |
| `chat/messages/{room_id}` | GET/POST | Message history / send message |
| `notifications/list` | POST | Notification list |
| `notifications/count` | GET | Unread notification count |

### 6.6 Static Content WebViews

| URL | Content |
|-----|---------|
| `{baseURL}get-static-page/webview?type=normal_terms_and_conditions` | End-user Terms & Conditions |
| `{baseURL}get-static-page/webview?type=normal_privacy_policy` | End-user Privacy Policy |

---

## 7. Professional REST API Endpoints

Base URL: `https://adminportal.verithrive.co.uk/api/api/v3/professional/`

### 7.1 Authentication & Account

| Endpoint | Method | Description |
|----------|--------|-------------|
| `send-otp` | POST | Send OTP |
| `verify-otp` | POST | Verify OTP |
| `register` | POST | Professional registration |
| `login` | POST | Email/password login |
| `social/check` | POST | Check if social account exists |
| `social/signin` | POST | Google/Apple social login |
| `logout` | POST | End session |
| `delete-account` | DELETE | Delete account |
| `forgot-password/send-otp` | POST | Send password reset OTP |
| `forgot-password/reset` | POST | Reset password |
| `change-password` | POST | Change password |

### 7.2 Profile Wizard

| Endpoint | Method | Description |
|----------|--------|-------------|
| `update-personal-details` | POST | Update personal info |
| `update-create-personal-details` | POST | Create/update during wizard |
| `get-personal-details` | GET | Fetch personal info |
| `create-profile` | POST | Profile photo and basic info |
| `get-create-profile-details` | GET | Fetch profile step data |
| `create-address` | POST | Work/service address |
| `get-create-address-details` | GET | Fetch address step data |
| `profession-types/all` | GET | Profession categories |
| `profession-sub-types/all` | GET | Profession sub-categories |
| `services/all` | GET | Available services catalog |
| `profession-services` | POST | Set professional services |
| `get-profession-services-details` | GET | Fetch services step data |
| `colleges-university` | GET | Qualification institution lookup |
| `qualifications/upsert` | POST | Add/update qualifications |
| `get-qualifications-details` | GET | Fetch qualifications step data |
| `personal-identification/upsert` | POST | Upload ID documents |
| `get-personal-identification-details` | GET | Fetch ID step data |
| `about-you` | POST | Bio and about section |
| `get-about-you-details` | GET | Fetch about step data |
| `get-profile-details` | GET | Full profile summary |
| `bank-details` | POST | Bank account for payouts |
| `get-static-page` | GET | Terms and privacy (WebView) |

### 7.3 Subscriptions & Payments

| Endpoint | Method | Description |
|----------|--------|-------------|
| `subscriptions/plans` | GET | Available subscription plans |
| `subscriptions/details` | GET | Current subscription details |
| `subscriptions/buy` | POST | Purchase subscription; returns Stripe Checkout URL |
| `subscriptions/cancel` | POST | Cancel subscription |
| `check-promo-code` | POST | Validate promotional code |

### 7.4 Service Formats & Availability

| Endpoint | Method | Description |
|----------|--------|-------------|
| `service-formats/all` | GET | All service format templates |
| `service-formats` | POST | Create service format |
| `service-formats/{id}` | PUT/DELETE | Update/delete service format |
| `availability` | POST | Create availability slot |
| `availability/{id}` | PUT/DELETE | Update/delete availability |
| `get-service-format-availability` | GET | Fetch availability for a format |

### 7.5 Bookings

| Endpoint | Method | Description |
|----------|--------|-------------|
| `bookings/list` | POST | List bookings |
| `bookings/{id}` | GET | Booking detail |
| `bookings/reschedule/{id}` | PUT | Reschedule booking |

### 7.6 Chat, Notifications & Transactions

| Endpoint | Method | Description |
|----------|--------|-------------|
| `chat/inbox` | POST | Chat inbox |
| `chat/room` | POST | Create/get chat room |
| `chat/messages/{roomId}` | GET/POST | Messages |
| `notification` | POST | Notification preferences |
| `notifications/list` | POST | Notification list |
| `notifications/count` | GET | Unread count |
| `transaction-history` | POST | Transaction history |
| `update-device-token` | POST | Sync FCM token |

### 7.7 Static Content WebViews

| URL | Content |
|-----|---------|
| `{baseURL}get-static-page/webview?type=professional_terms_and_conditions` | Professional Terms & Conditions |
| `{baseURL}get-static-page/webview?type=professional_privacy_policy` | Professional Privacy Policy |

---

## 8. Socket.IO Real-Time API

| Property | Value |
|----------|-------|
| **Server** | `https://adminportal.verithrive.co.uk` |
| **Path** | `/socket.io` |
| **Auth** | Bearer token in connection headers and `setAuth({'token': token})` |

### Events

| Event | Direction | Description |
|-------|-----------|-------------|
| `get_inbox` | Client → Server | Request inbox data |
| `inbox_data` | Server → Client | Inbox payload |
| `send_message` | Client → Server | Send a chat message |
| `receive_message` | Server → Client | Incoming message |
| `mark_read` | Client → Server | Mark messages as read |
| `user_connection_status` | Server → Client | Online/offline status |

**Implementation files:**
- Professional: `lib/services/socket_service.dart`
- End User: `lib/enduser/screens/message/socket_service.dart`

---

## 9. External API Keys & Configuration

| Key / Config | Location | Notes |
|--------------|----------|-------|
| Firebase Android API key | `lib/common/firebase_config.dart` | Committed in source |
| Google Maps API key (Android) | `android/app/src/main/AndroidManifest.xml` | Required for map display |
| Google Maps API key (iOS) | `ios/Runner/Info.plist` | Required for map display |
| Google Places API key | `lib/enduser/screens/select_address/SelectAddressMapView.dart`, `lib/professional/select_address_map/select_address_map_view.dart` | Address autocomplete |
| Firebase config (Android) | `android/app/google-services.json` | Not in version control |
| Firebase config (iOS) | `ios/Runner/GoogleService-Info.plist` | Not in version control |
| Android release signing | `android/key.properties` | Not in version control |

---

## 10. Push Notification Event Types

Handled by `ForegroundNotificationService` and end-user notification routing:

| Type | Description |
|------|-------------|
| `booking_rescheduled_by_professional` | Booking rescheduled |
| `booking_cancelled_by_professional` | Booking cancelled |
| `booking_*_reminder` | Pre-session reminders |
| `booking_started` | Session started |
| `booking_ended` | Session ended |
| `booking_completed_review` | Prompt to leave review |
| `review_reminder` | Review reminder |
| `final_review_reminder` | Final review reminder |
| `chat_message` | New chat message |

---

## 11. Related Documents

- [Application Architecture](./ARCHITECTURE.md)
- [User & System Flows](./USER_AND_SYSTEM_FLOWS.md)
- [Project Setup & Build Guide](PROJECT_DOCUMENTATION.md)
