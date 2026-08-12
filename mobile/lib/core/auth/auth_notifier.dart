import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import 'auth_state.dart';

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

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
              .eq('user_id', currentUser.id) as List<dynamic>;

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

        // Authenticated but no tenant joined/created yet
        state = state.copyWith(
          status: AuthStatus.authenticatedNoTenant,
          userId: userId,
          userEmail: userEmail,
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
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (res.user != null) {
          await initializeAuth();
          return true;
        }
      }
      // Demo / fallback mode
      await signInDemoUser();
      return true;
    } catch (e) {
      debugPrint('Email Sign-In error: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign Up with Email & Password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.auth.signUp(
          email: email,
          password: password,
        );
        if (res.user != null) {
          await initializeAuth();
          return true;
        }
      }
      // Demo fallback mode for new user
      state = state.copyWith(
        status: AuthStatus.authenticatedNoTenant,
        userId: 'demo-user-new',
        userEmail: email,
      );
      return true;
    } catch (e) {
      debugPrint('Email Sign-Up error: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Create Canteen RPC Call (`create_tenant`)
  Future<bool> createTenant(String name) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
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
          return true;
        } else {
          final errMessage = res['error']?['message'] as String? ??
              'Failed to create canteen';
          state = state.copyWith(
            status: AuthStatus.authenticatedNoTenant,
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
      return true;
    } catch (e) {
      debugPrint('createTenant error: $e');
      state = state.copyWith(
        status: AuthStatus.authenticatedNoTenant,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Join Canteen via Invite Code RPC (`join_tenant_by_code`)
  Future<bool> joinTenant(String code) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
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
          return true;
        } else {
          final errMessage = res['error']?['message'] as String? ??
              'Invalid or expired invite code';
          state = state.copyWith(
            status: AuthStatus.authenticatedNoTenant,
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
      return true;
    } catch (e) {
      debugPrint('joinTenant error: $e');
      state = state.copyWith(
        status: AuthStatus.authenticatedNoTenant,
        errorMessage: e.toString(),
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
      tenantId: tenantId,
      tenantName: tenantName,
      role: role,
    );
  }

  /// Initiate Native Google Sign-In with 1-tap Account Picker & Supabase token exchange
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      if (SupabaseService.isInitialized) {
        final googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          // User cancelled sign-in sheet
          state = state.copyWith(status: AuthStatus.unauthenticated);
          return;
        }

        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;

        if (idToken == null) {
          throw Exception('Failed to obtain Google ID Token.');
        }

        // Exchange Google ID Token with Supabase Auth session
        final res = await SupabaseService.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        if (res.user != null) {
          await initializeAuth();
          return;
        }
      }

      // Fallback for offline or test mode
      await signInDemoUser();
    } catch (e) {
      debugPrint('Google Native Sign-In error: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  /// Demo / Simulator sign-in helper
  Future<void> signInDemoUser() async {
    state = state.copyWith(status: AuthStatus.loading);
    await Future.delayed(const Duration(milliseconds: 600));

    const demoUser = {
      'id': 'demo-owner-123',
      'email': 'owner@canteen.bd',
    };
    const demoTenant = {
      'id': 'tenant-demo-001',
      'name': 'Bismillah Canteen',
      'role': 'owner',
    };

    await HiveService.setCache('active_user', demoUser);
    await HiveService.setCache('active_tenant', demoTenant);

    state = state.copyWith(
      status: AuthStatus.authenticatedWithTenant,
      userId: demoUser['id'],
      userEmail: demoUser['email'],
      tenantId: demoTenant['id'],
      tenantName: demoTenant['name'],
      role: demoTenant['role'],
    );
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
