import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import 'auth_state.dart';

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

enum SignUpResult {
  successAccountCreated,
  successAuthenticated,
  confirmationEmailSent,
  failed,
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Check session on startup (called during Splash screen)
  Future<void> initializeAuth() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      // 1. Check local Hive cache for offline tenant info
      final cachedTenant = HiveService.getCache('active_tenant');
      final cachedUser = HiveService.getCache('active_user');

      // 2. Check Supabase session
      final currentUser = SupabaseService.isInitialized
          ? SupabaseService.client.auth.currentUser
          : null;

      if (currentUser == null && cachedUser == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      final userId = currentUser?.id ?? cachedUser?['id'] as String?;
      final userEmail = currentUser?.email ?? cachedUser?['email'] as String?;

      if (cachedTenant != null && cachedTenant['id'] != null) {
        state = state.copyWith(
          status: AuthStatus.authenticatedWithTenant,
          userId: userId,
          userEmail: userEmail,
          tenantId: cachedTenant['id'] as String?,
          tenantName: cachedTenant['name'] as String?,
          role: cachedTenant['role'] as String? ?? 'owner',
        );
        return;
      }

      // If user is authenticated via Supabase, attempt fetching tenant membership
      if (currentUser != null) {
        try {
          final memberships = await SupabaseService.client
              .from('tenant_members')
              .select('tenant_id, role, tenants(id, name)')
              .eq('user_id', currentUser.id)
              .timeout(const Duration(seconds: 3)) as List<dynamic>;

          if (memberships.isNotEmpty) {
            final firstMem = memberships.first as Map<String, dynamic>;
            final tenantObj = firstMem['tenants'] as Map<String, dynamic>?;
            final tId = firstMem['tenant_id'] as String? ?? tenantObj?['id'] as String?;
            final tName = tenantObj?['name'] as String? ?? 'My Canteen';
            final role = firstMem['role'] as String? ?? 'owner';

            // Cache locally
            await HiveService.setCache('active_tenant', {
              'id': tId,
              'name': tName,
              'role': role,
            });

            state = state.copyWith(
              status: AuthStatus.authenticatedWithTenant,
              userId: userId,
              userEmail: userEmail,
              tenantId: tId,
              tenantName: tName,
              role: role,
            );
            return;
          }
        } catch (e) {
          debugPrint('AuthNotifier membership check warning: $e');
        }

        // Authenticated user with no tenant membership -> OnboardingChoiceScreen
        state = state.copyWith(
          status: AuthStatus.authenticatedNoTenant,
          userId: userId,
          userEmail: userEmail,
          isSubmitting: false,
        );
        return;
      }

      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      debugPrint('AuthNotifier initialization error: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sign In with Email & Password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (res.user != null) {
          await initializeAuth();
          state = state.copyWith(isSubmitting: false);
          return true;
        }
      }
      // Demo / fallback mode
      await signInDemoUser(email: email);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      debugPrint('Email Sign-In error: $e');
      final isDemoAccount = email == 'owner@gmail.com' || email == 'manager@gmail.com';
      if (isDemoAccount) {
        debugPrint('Falling back to local demo sign-in for $email');
        await signInDemoUser(email: email);
        state = state.copyWith(isSubmitting: false);
        return true;
      }

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isSubmitting: false,
        errorMessage: _cleanErrorMessage(e),
      );
      return false;
    }
  }

  /// Sign Up with Email & Password (Triggers email confirmation code)
  Future<SignUpResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.auth.signUp(
          email: email,
          password: password,
        );
        if (res.user != null) {
          if (res.session != null) {
            await initializeAuth();
            state = state.copyWith(isSubmitting: false);
            return SignUpResult.successAuthenticated;
          } else {
            // Email confirmation code required
            state = state.copyWith(
              status: AuthStatus.unauthenticated,
              isSubmitting: false,
              errorMessage: null,
            );
            return SignUpResult.confirmationEmailSent;
          }
        }
      }
      // Demo / fallback mode for confirmation code testing
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isSubmitting: false,
      );
      return SignUpResult.confirmationEmailSent;
    } catch (e) {
      debugPrint('Email Sign-Up error: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isSubmitting: false,
        errorMessage: _cleanErrorMessage(e),
      );
      return SignUpResult.failed;
    }
  }

  /// Verify Email 6-Digit Confirmation OTP Code
  Future<bool> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.auth.verifyOTP(
          email: email,
          token: token,
          type: OtpType.signup,
        );
        if (res.session != null || res.user != null) {
          await initializeAuth();
          state = state.copyWith(isSubmitting: false);
          return true;
        } else {
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: 'Invalid or expired confirmation code.',
          );
          return false;
        }
      }

      // Demo mode fallback for offline/local testing
      state = state.copyWith(
        status: AuthStatus.authenticatedNoTenant,
        isSubmitting: false,
        userId: 'demo-user-verified',
        userEmail: email,
      );
      return true;
    } catch (e) {
      debugPrint('verifyEmailOtp error: $e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _cleanErrorMessage(e),
      );
      return false;
    }
  }

  /// Resend 6-Digit Email OTP
  Future<bool> resendEmailOtp({required String email}) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      if (SupabaseService.isInitialized) {
        await SupabaseService.client.auth.resend(
          email: email,
          type: OtpType.signup,
        );
      }
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      debugPrint('resendEmailOtp error: $e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _cleanErrorMessage(e),
      );
      return false;
    }
  }

  /// Create Canteen RPC Call (`create_tenant`)
  Future<bool> createTenant(String name) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.rpc('create_tenant', params: {
          'p_name': name,
        }) as Map<String, dynamic>;

        if (res['success'] == true && res['data'] != null) {
          final data = res['data'] as Map<String, dynamic>;
          await setActiveTenant(
            tenantId: data['tenant_id'] as String,
            tenantName: data['name'] as String? ?? name,
            role: data['role'] as String? ?? 'owner',
          );
          state = state.copyWith(isSubmitting: false);
          return true;
        } else {
          final errMessage = res['error']?['message'] as String? ??
              'Failed to create canteen';
          state = state.copyWith(
            status: AuthStatus.authenticatedNoTenant,
            isSubmitting: false,
            errorMessage: errMessage,
          );
          return false;
        }
      }

      // Demo mode fallback
      await setActiveTenant(
        tenantId: 'tenant-${DateTime.now().millisecondsSinceEpoch}',
        tenantName: name,
        role: 'owner',
      );
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      debugPrint('createTenant error: $e');
      state = state.copyWith(
        status: AuthStatus.authenticatedNoTenant,
        isSubmitting: false,
        errorMessage: _cleanErrorMessage(e),
      );
      return false;
    }
  }

  /// Join Canteen via Invite Code RPC (`join_tenant_by_code`)
  Future<bool> joinTenant(String code) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      if (SupabaseService.isInitialized) {
        final res =
            await SupabaseService.client.rpc('join_tenant_by_code', params: {
          'p_code': code,
        }) as Map<String, dynamic>;

        if (res['success'] == true && res['data'] != null) {
          final data = res['data'] as Map<String, dynamic>;
          await setActiveTenant(
            tenantId: data['tenant_id'] as String,
            tenantName: data['name'] as String? ?? 'Joined Canteen',
            role: data['role'] as String? ?? 'manager',
          );
          state = state.copyWith(isSubmitting: false);
          return true;
        } else {
          final errMessage = res['error']?['message'] as String? ??
              'Invalid or expired invite code';
          state = state.copyWith(
            status: AuthStatus.authenticatedNoTenant,
            isSubmitting: false,
            errorMessage: errMessage,
          );
          return false;
        }
      }

      // Demo mode fallback
      await setActiveTenant(
        tenantId: 'tenant-joined-$code',
        tenantName: 'Demo Joined Canteen',
        role: 'manager',
      );
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      debugPrint('joinTenant error: $e');
      state = state.copyWith(
        status: AuthStatus.authenticatedNoTenant,
        isSubmitting: false,
        errorMessage: _cleanErrorMessage(e),
      );
      return false;
    }
  }

  /// Manually update tenant after creating/joining
  Future<void> setActiveTenant({
    required String tenantId,
    required String tenantName,
    required String role,
  }) async {
    await HiveService.setCache('active_tenant', {
      'id': tenantId,
      'name': tenantName,
      'role': role,
    });

    state = state.copyWith(
      status: AuthStatus.authenticatedWithTenant,
      isSubmitting: false,
      tenantId: tenantId,
      tenantName: tenantName,
      role: role,
    );
  }

  /// Demo / Simulator sign-in helper for quick local testing
  Future<void> signInDemoUser({String email = 'owner@gmail.com'}) async {
    state = state.copyWith(isSubmitting: true);
    await Future.delayed(const Duration(milliseconds: 400));

    final isManager = email.toLowerCase().contains('manager');
    final role = isManager ? 'manager' : 'owner';
    final userId = isManager
        ? '22222222-2222-2222-2222-222222222222'
        : '11111111-1111-1111-1111-111111111111';

    final demoUser = {
      'id': userId,
      'email': email,
    };
    const demoTenant = {
      'id': '00000000-0000-0000-0000-000000000001',
      'name': 'Bismillah Canteen',
    };

    await HiveService.setCache('active_user', demoUser);
    await HiveService.setCache('active_tenant', {
      ...demoTenant,
      'role': role,
    });

    state = state.copyWith(
      status: AuthStatus.authenticatedWithTenant,
      isSubmitting: false,
      userId: userId,
      userEmail: email,
      tenantId: demoTenant['id'],
      tenantName: demoTenant['name'],
      role: role,
    );
  }

  /// Format raw exception strings into user-friendly notifications
  String _cleanErrorMessage(dynamic e) {
    final str = e.toString();
    if (str.contains('Database error querying schema') || str.contains('statusCode: 500')) {
      return 'Server error during authentication. Please try again or use Demo Mode.';
    }
    if (str.contains('Invalid login credentials') || str.contains('invalid_credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (str.contains('User already registered') || str.contains('user_already_exists')) {
      return 'An account with this email already exists. Please Sign In.';
    }
    if (str.contains('SocketException') || str.contains('NetworkException')) {
      return 'Network error. Please check your internet connection.';
    }
    return str.replaceAll(RegExp(r'^AuthException\(|\)$'), '').trim();
  }

  /// Delete User Account and associated data
  Future<bool> deleteAccount() async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.rpc('delete_user_account')
            as Map<String, dynamic>?;

        if (res != null && res['success'] == false) {
          final errMessage = res['error']?['message'] as String? ??
              'Failed to delete user account.';
          state = state.copyWith(isSubmitting: false, errorMessage: errMessage);
          return false;
        }
      }

      // Purge cached session data
      await HiveService.deleteCache('active_tenant');
      await HiveService.deleteCache('active_user');

      try {
        await SupabaseService.client.auth.signOut();
      } catch (_) {}

      state = const AuthState(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      debugPrint('deleteAccount error: $e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _cleanErrorMessage(e),
      );
      return false;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await SupabaseService.client.auth.signOut();
    } catch (_) {}
    await HiveService.deleteCache('active_tenant');
    await HiveService.deleteCache('active_user');

    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
