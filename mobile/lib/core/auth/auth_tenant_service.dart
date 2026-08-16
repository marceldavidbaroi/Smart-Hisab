import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';
import 'auth_state.dart';

/// Data service handling Supabase database RPCs for Canteen / Tenant operations
class AuthTenantService {
  AuthTenantService._();

  /// Fetch user memberships
  static Future<List<TenantMembershipItem>> fetchUserTenants(String userId) async {
    try {
      if (!SupabaseService.isInitialized) return [];

      final memberships = await SupabaseService.client
          .from('tenant_members')
          .select('tenant_id, role, tenants(id, name)')
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 4)) as List<dynamic>;

      final list = memberships
          .map((m) => TenantMembershipItem.fromMap(m as Map<String, dynamic>))
          .toList();

      return list;
    } catch (e) {
      debugPrint('AuthTenantService fetchUserTenants error: $e');
      return [];
    }
  }

  /// Create Canteen RPC Call (`create_tenant`)
  /// Returns dynamic: Postgres returns UUID string directly
  static Future<dynamic> createTenant(String name) async {
    if (!SupabaseService.isInitialized) return null;
    return await SupabaseService.client.rpc('create_tenant', params: {
      'p_name': name,
    });
  }

  /// Join Canteen via Invite Code RPC (`join_tenant_by_code`)
  /// Returns dynamic: Postgres returns JSON object with tenant_id, name, role
  static Future<dynamic> joinTenant(String code) async {
    if (!SupabaseService.isInitialized) return null;
    return await SupabaseService.client.rpc('join_tenant_by_code', params: {
      'p_code': code,
    });
  }

  /// Delete Canteen RPC Call (`delete_canteen`)
  static Future<Map<String, dynamic>?> deleteCanteen(String tenantId) async {
    if (!SupabaseService.isInitialized) return null;
    return await SupabaseService.client.rpc('delete_canteen', params: {
      'p_tenant_id': tenantId,
    }) as Map<String, dynamic>?;
  }

  /// Leave Canteen RPC Call (`leave_canteen`)
  static Future<Map<String, dynamic>?> leaveCanteen(String tenantId) async {
    if (!SupabaseService.isInitialized) return null;
    return await SupabaseService.client.rpc('leave_canteen', params: {
      'p_tenant_id': tenantId,
    }) as Map<String, dynamic>?;
  }

  /// Delete Account RPC Call (`delete_user_account`)
  static Future<Map<String, dynamic>?> deleteAccount() async {
    if (!SupabaseService.isInitialized) return null;
    return await SupabaseService.client.rpc('delete_user_account') as Map<String, dynamic>?;
  }
}
