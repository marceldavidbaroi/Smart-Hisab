import '../services/hive_service.dart';
import 'auth_state.dart';

/// Helper service for offline / simulator demo account sign-in
class AuthDemoService {
  AuthDemoService._();

  static Future<AuthState> buildDemoAuthState(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final isManager = email.toLowerCase().contains('manager');
    final role = isManager ? 'manager' : 'owner';
    final userId = isManager
        ? '22222222-2222-2222-2222-222222222222'
        : '11111111-1111-1111-1111-111111111111';

    final demoUser = {'id': userId, 'email': email};

    await HiveService.setCache('active_user', demoUser);
    await HiveService.deleteCache('active_tenant');

    final demoTenants = [
      const TenantMembershipItem(
        tenantId: '00000000-0000-0000-0000-000000000001',
        tenantName: 'Bismillah Canteen',
        role: 'owner',
      ),
      const TenantMembershipItem(
        tenantId: '00000000-0000-0000-0000-000000000002',
        tenantName: 'Al-Madina Restora & Canteen',
        role: 'manager',
      ),
    ];

    return AuthState(
      status: AuthStatus.authenticatedSelectTenant,
      isSubmitting: false,
      userId: userId,
      userEmail: email,
      role: role,
      availableTenants: demoTenants,
    );
  }
}
