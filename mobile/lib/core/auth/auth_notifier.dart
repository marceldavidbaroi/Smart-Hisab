import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/error_handler_service.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import 'auth_demo_service.dart';
import 'auth_email_service.dart';
import 'auth_error_formatter.dart';
import 'auth_state.dart';
import 'auth_tenant_service.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

enum SignUpResult {
  successAccountCreated,
  successAuthenticated,
  confirmationEmailSent,
  failed,
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Check session on startup & evaluate tenant count
  Future<void> initializeAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final cachedTenant = HiveService.getCache('active_tenant');
      final cachedUser = HiveService.getCache('active_user');
      final currentUser = SupabaseService.isInitialized ? SupabaseService.client.auth.currentUser : null;

      if (currentUser == null && cachedUser == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      final userId = currentUser?.id ?? cachedUser?['id'] as String?;
      final userEmail = currentUser?.email ?? cachedUser?['email'] as String?;

      if (currentUser != null) {
        List<TenantMembershipItem> tenantList = [];
        try {
          tenantList = await AuthTenantService.fetchUserTenants(currentUser.id);
        } catch (e) {
          debugPrint('AuthTenantService error handled during init: $e');
        }
        _resolveUserTenantsState(userId, userEmail, tenantList, cachedTenant);
        return;
      }

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

      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      debugPrint('AuthNotifier initialization error: $e');
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: e.toString());
    }
  }

  void _resolveUserTenantsState(
    String? userId,
    String? userEmail,
    List<TenantMembershipItem> tenantList,
    dynamic cachedTenant,
  ) {
    if (tenantList.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.authenticatedNoTenant,
        userId: userId,
        userEmail: userEmail,
        availableTenants: [],
        isSubmitting: false,
      );
      return;
    }

    if (tenantList.length == 1) {
      final mem = tenantList.first;
      setActiveTenant(tenantId: mem.tenantId, tenantName: mem.tenantName, role: mem.role);
      state = state.copyWith(userId: userId, userEmail: userEmail, availableTenants: tenantList);
      return;
    }

    if (cachedTenant != null && cachedTenant['id'] != null) {
      state = state.copyWith(
        status: AuthStatus.authenticatedWithTenant,
        userId: userId,
        userEmail: userEmail,
        tenantId: cachedTenant['id'] as String?,
        tenantName: cachedTenant['name'] as String?,
        role: cachedTenant['role'] as String? ?? 'owner',
        availableTenants: tenantList,
      );
      return;
    }

    state = state.copyWith(
      status: AuthStatus.authenticatedSelectTenant,
      userId: userId,
      userEmail: userEmail,
      availableTenants: tenantList,
      isSubmitting: false,
    );
  }

  void openSelectCanteenScreen() {
    state = state.copyWith(status: AuthStatus.authenticatedSelectTenant);
  }

  Future<bool> signInWithEmail({required String email, required String password}) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail == 'owner@gmail.com' || cleanEmail == 'manager@gmail.com') {
      await signInDemoUser(email: cleanEmail);
      return true;
    }

    try {
      await HiveService.deleteCache('active_tenant');
      final res = await AuthEmailService.signInWithPassword(cleanEmail, password);
      if (res?.user != null) {
        await initializeAuth();
        state = state.copyWith(isSubmitting: false);
        return true;
      }
      await signInDemoUser(email: cleanEmail);
      return true;
    } catch (e) {
      debugPrint('Email Sign-In error: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('database error') ||
          errStr.contains('schema') ||
          errStr.contains('unexpected_failure') ||
          errStr.contains('500')) {
        await signInDemoUser(email: cleanEmail);
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isSubmitting: false,
        errorMessage: AuthErrorFormatter.format(e),
      );
      return false;
    }
  }

  Future<SignUpResult> signUpWithEmail({required String email, required String password}) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final res = await AuthEmailService.signUp(email, password);
      if (res?.user != null) {
        if (res?.session != null) {
          await initializeAuth();
          state = state.copyWith(isSubmitting: false);
          return SignUpResult.successAuthenticated;
        }
        state = state.copyWith(status: AuthStatus.unauthenticated, isSubmitting: false);
        return SignUpResult.confirmationEmailSent;
      }
      state = state.copyWith(status: AuthStatus.unauthenticated, isSubmitting: false);
      return SignUpResult.confirmationEmailSent;
    } catch (e) {
      debugPrint('Email Sign-Up error: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isSubmitting: false,
        errorMessage: AuthErrorFormatter.format(e),
      );
      return SignUpResult.failed;
    }
  }

  Future<bool> verifyEmailOtp({required String email, required String token}) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final res = await AuthEmailService.verifyOTP(email, token);
      if (res?.session != null || res?.user != null) {
        await initializeAuth();
        state = state.copyWith(isSubmitting: false);
        return true;
      } else if (SupabaseService.isInitialized) {
        state = state.copyWith(isSubmitting: false, errorMessage: 'Invalid or expired confirmation code.');
        return false;
      }
      state = state.copyWith(
        status: AuthStatus.authenticatedNoTenant,
        isSubmitting: false,
        userId: 'demo-user-verified',
        userEmail: email,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: AuthErrorFormatter.format(e));
      return false;
    }
  }

  Future<bool> resendEmailOtp({required String email}) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      await AuthEmailService.resendOTP(email);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: AuthErrorFormatter.format(e));
      return false;
    }
  }

  static bool _isValidUuid(String id) {
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(id);
  }

  Future<bool> createTenant(String name) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final currentUser = SupabaseService.isInitialized ? SupabaseService.client.auth.currentUser : null;
      String newTenantId;
      String finalName = name;
      String finalRole = 'owner';

      if (currentUser != null) {
        final res = await AuthTenantService.createTenant(name);
        if (res != null) {
          if (res is String) {
            newTenantId = res;
          } else if (res is Map<String, dynamic>) {
            if (res['success'] == false) {
              ErrorHandlerService.handleApiResponse(res, 'Create Canteen Error');
              final errMessage = res['error']?['message'] as String? ?? 'Failed to create canteen.';
              state = state.copyWith(isSubmitting: false, errorMessage: errMessage);
              return false;
            }
            final data = (res['data'] is Map<String, dynamic>) ? res['data'] as Map<String, dynamic> : res;
            newTenantId = data['tenant_id'] as String? ?? (data['id'] as String? ?? '');
            finalName = data['name'] as String? ?? name;
            finalRole = data['role'] as String? ?? 'owner';
          } else {
            newTenantId = res.toString();
          }
        } else {
          state = state.copyWith(isSubmitting: false, errorMessage: 'Failed to create canteen on server.');
          return false;
        }

        if (newTenantId.isEmpty || !_isValidUuid(newTenantId)) {
          state = state.copyWith(isSubmitting: false, errorMessage: 'Server returned an invalid canteen ID.');
          return false;
        }
      } else {
        newTenantId = 'tenant-${DateTime.now().millisecondsSinceEpoch}';
      }

      final newItem = TenantMembershipItem(
        tenantId: newTenantId,
        tenantName: finalName,
        role: finalRole,
      );

      final baseList = state.availableTenants;
      final updatedList = [...baseList.where((t) => t.tenantId != newTenantId), newItem];
      await setActiveTenant(
        tenantId: newTenantId,
        tenantName: finalName,
        role: finalRole,
      );
      state = state.copyWith(availableTenants: updatedList, isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: AuthErrorFormatter.format(e),
      );
      return false;
    }
  }

  Future<bool> joinTenant(String code) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final currentUser = SupabaseService.isInitialized ? SupabaseService.client.auth.currentUser : null;
      String joinedTenantId;
      String joinedName = 'Joined Canteen ($code)';
      String joinedRole = 'manager';

      if (currentUser != null) {
        final res = await AuthTenantService.joinTenant(code);
        if (res != null) {
          if (res is Map<String, dynamic>) {
            if (res['success'] == false) {
              ErrorHandlerService.handleApiResponse(res, 'Join Canteen Error');
              final errMessage = res['error']?['message'] as String? ?? 'Failed to join canteen.';
              state = state.copyWith(isSubmitting: false, errorMessage: errMessage);
              return false;
            }
            final data = (res['data'] is Map<String, dynamic>) ? res['data'] as Map<String, dynamic> : res;
            joinedTenantId = data['tenant_id'] as String? ?? (data['id'] as String? ?? '');
            joinedName = data['name'] as String? ?? joinedName;
            joinedRole = data['role'] as String? ?? 'manager';
          } else if (res is String) {
            joinedTenantId = res;
          } else {
            joinedTenantId = '';
          }
        } else {
          state = state.copyWith(isSubmitting: false, errorMessage: 'Failed to join canteen on server.');
          return false;
        }

        if (joinedTenantId.isEmpty || !_isValidUuid(joinedTenantId)) {
          state = state.copyWith(isSubmitting: false, errorMessage: 'Invalid invite code or server returned invalid ID.');
          return false;
        }
      } else {
        joinedTenantId = 'tenant-joined-$code';
      }

      final newItem = TenantMembershipItem(
        tenantId: joinedTenantId,
        tenantName: joinedName,
        role: joinedRole,
      );

      List<TenantMembershipItem> updatedList;
      if (currentUser != null) {
        final fetchedTenants = await AuthTenantService.fetchUserTenants(currentUser.id);
        updatedList = fetchedTenants.isNotEmpty
            ? fetchedTenants
            : [...state.availableTenants.where((t) => t.tenantId != joinedTenantId), newItem];
      } else {
        updatedList = [...state.availableTenants.where((t) => t.tenantId != joinedTenantId), newItem];
      }

      await setActiveTenant(
        tenantId: joinedTenantId,
        tenantName: joinedName,
        role: joinedRole,
      );
      state = state.copyWith(availableTenants: updatedList, isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: AuthErrorFormatter.format(e),
      );
      return false;
    }
  }

  Future<bool> deleteCanteen(String tenantId) async {
    return _performCanteenAction(() => AuthTenantService.deleteCanteen(tenantId), tenantId);
  }

  Future<bool> leaveCanteen(String tenantId) async {
    return _performCanteenAction(() => AuthTenantService.leaveCanteen(tenantId), tenantId);
  }

  Future<bool> _performCanteenAction(Future<Map<String, dynamic>?> Function() action, String tenantId) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final currentUser = SupabaseService.isInitialized ? SupabaseService.client.auth.currentUser : null;
      if (currentUser != null && _isValidUuid(tenantId)) {
        final res = await action();
        if (res != null && res['success'] == false) {
          ErrorHandlerService.handleApiResponse(res, 'Canteen Action Error');
          final errMessage = res['error']?['message'] as String? ?? 'Failed to perform canteen action.';
          debugPrint('Canteen RPC warning: $errMessage');
          state = state.copyWith(isSubmitting: false, errorMessage: errMessage);
          return false;
        }
      }
      await _handleCanteenRemoved(tenantId);
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      await _handleCanteenRemoved(tenantId);
      state = state.copyWith(isSubmitting: false);
      return true;
    }
  }

  Future<void> _handleCanteenRemoved(String removedTenantId) async {
    final baseList = state.availableTenants;
    final updatedList = baseList.where((t) => t.tenantId != removedTenantId).toList();
    final wasActive = state.tenantId == removedTenantId;

    if (!wasActive) {
      // Deleting non-active canteen: Only mutate availableTenants list locally. ZERO secondary API calls!
      state = state.copyWith(availableTenants: updatedList);
      return;
    }

    // Deleting active canteen: Clear active tenant cache without triggering secondary API calls
    await HiveService.deleteCache('active_tenant');

    if (updatedList.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.authenticatedNoTenant,
        tenantId: null,
        tenantName: null,
        role: null,
        availableTenants: const [],
      );
    } else {
      // Set status to select tenant without auto-fetching secondary endpoints until user selects a canteen
      state = state.copyWith(
        status: AuthStatus.authenticatedSelectTenant,
        tenantId: null,
        tenantName: null,
        role: null,
        availableTenants: updatedList,
      );
    }
  }

  Future<void> setActiveTenant({
    required String tenantId,
    required String tenantName,
    required String role,
  }) async {
    await HiveService.setCache('active_tenant', {'id': tenantId, 'name': tenantName, 'role': role});
    state = state.copyWith(
      status: AuthStatus.authenticatedWithTenant,
      isSubmitting: false,
      tenantId: tenantId,
      tenantName: tenantName,
      role: role,
    );
  }

  Future<void> signInDemoUser({String email = 'owner@gmail.com'}) async {
    state = state.copyWith(isSubmitting: true);
    final demoState = await AuthDemoService.buildDemoAuthState(email);
    state = demoState;
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final res = await AuthTenantService.deleteAccount();
      if (res != null && res['success'] == false) {
        ErrorHandlerService.handleApiResponse(res, 'Delete Account Error');
        final errMessage = res['error']?['message'] as String? ?? 'Failed to delete user account.';
        state = state.copyWith(isSubmitting: false, errorMessage: errMessage);
        return false;
      }
      await HiveService.deleteCache('active_tenant');
      await HiveService.deleteCache('active_user');
      try {
        await AuthEmailService.signOut();
      } catch (_) {}

      state = const AuthState(status: AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: AuthErrorFormatter.format(e));
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await AuthEmailService.signOut();
    } catch (_) {}
    await HiveService.deleteCache('active_tenant');
    await HiveService.deleteCache('active_user');
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
