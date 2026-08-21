# Screen: Login & OTP Verification

## 1. Screen Identity & Hierarchy
* **Screen / Widget Classes**: `LoginScreen`, `VerifyEmailScreen`
* **Dart Source Files**: [login_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/login_screen.dart), [verify_email_screen.dart](file:///Users/daviditc/Documents/personal_projects/smart-hisab/mobile/lib/features/auth/verify_email_screen.dart)
* **Parent / Hosting Shell**: Standalone Auth Flow Route (pushed from `LandingScreen`)

---

## 2. Initial Load & Riverpod State

### A. Initial Fetch
* Checks if auth session already exists in `supabase.auth.currentSession`.

### B. Riverpod State
* **Provider Name**: `authNotifierProvider`
* **Type**: `Notifier<AuthState>`
* **Local Cache**: Secure Storage (JWT token) + Hive (User Profile)

---

## 3. User Actions & Mutation Matrix

| Action Name | Trigger / UI Element | Riverpod Method | API / RPC Responsible | Targeted Cache Mutation Rule |
| :--- | :--- | :--- | :--- | :--- |
| **Send OTP** | Tap "Send Login Code" | `sendOtp(email/phone)` | `supabase.auth.signInWithOtp` | Sets UI state to `OtpSent` state. |
| **Verify OTP** | Tap "Verify & Login" | `verifyOtp(token)` | `supabase.auth.verifyOTP` | Sets `AuthState.authenticated`, triggers membership lookup. |

---

## 4. Complete API & RPC Specifications

### 1. `supabase.auth.signInWithOtp`
* **Payload**: `{"email": "owner@canteen.com"}`
* **Response**: `{"message": "OTP sent successfully"}`

### 2. `supabase.auth.verifyOTP`
* **Payload**: `{"email": "owner@canteen.com", "token": "123456", "type": "email"}`
* **Response**: `{"session": {"access_token": "jwt...", "user": {"id": "uuid"}}}`
