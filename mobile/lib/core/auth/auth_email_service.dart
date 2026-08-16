import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

/// Data service handling Supabase Auth operations (email login, signup, OTP)
class AuthEmailService {
  AuthEmailService._();

  static Future<AuthResponse?> signInWithPassword(String email, String password) async {
    if (!SupabaseService.isInitialized) return null;
    return await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse?> signUp(String email, String password) async {
    if (!SupabaseService.isInitialized) return null;
    return await SupabaseService.client.auth.signUp(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse?> verifyOTP(String email, String token) async {
    if (!SupabaseService.isInitialized) return null;
    return await SupabaseService.client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  static Future<void> resendOTP(String email) async {
    if (!SupabaseService.isInitialized) return;
    await SupabaseService.client.auth.resend(
      email: email,
      type: OtpType.signup,
    );
  }

  static Future<void> signOut() async {
    if (!SupabaseService.isInitialized) return;
    await SupabaseService.client.auth.signOut();
  }
}
