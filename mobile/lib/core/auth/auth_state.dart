import 'package:flutter/foundation.dart';

enum AuthStatus {
  initial,
  loading,
  unauthenticated,
  authenticatedNoTenant,
  authenticatedSelectTenant,
  authenticatedWithTenant,
  error,
}

@immutable
class TenantMembershipItem {
  final String tenantId;
  final String tenantName;
  final String role; // 'owner' or 'manager'

  const TenantMembershipItem({
    required this.tenantId,
    required this.tenantName,
    required this.role,
  });

  factory TenantMembershipItem.fromMap(Map<String, dynamic> map) {
    final tenantObj = map['tenants'] as Map<String, dynamic>?;
    return TenantMembershipItem(
      tenantId: map['tenant_id'] as String? ?? tenantObj?['id'] as String? ?? map['id'] as String? ?? '',
      tenantName: tenantObj?['name'] as String? ?? map['name'] as String? ?? 'Canteen',
      role: map['role'] as String? ?? 'owner',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': tenantId,
      'name': tenantName,
      'role': role,
    };
  }
}

@immutable
class AuthState {
  final AuthStatus status;
  final bool isSubmitting;
  final String? userId;
  final String? userEmail;
  final String? tenantId;
  final String? tenantName;
  final String? role; // 'owner' or 'manager'
  final List<TenantMembershipItem> availableTenants;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.isSubmitting = false,
    this.userId,
    this.userEmail,
    this.tenantId,
    this.tenantName,
    this.role,
    this.availableTenants = const [],
    this.errorMessage,
  });

  bool get isLoading => status == AuthStatus.initial || status == AuthStatus.loading;
  bool get isAuthenticated =>
      status == AuthStatus.authenticatedNoTenant ||
      status == AuthStatus.authenticatedSelectTenant ||
      status == AuthStatus.authenticatedWithTenant;
  bool get hasTenant => status == AuthStatus.authenticatedWithTenant;

  AuthState copyWith({
    AuthStatus? status,
    bool? isSubmitting,
    String? userId,
    String? userEmail,
    String? tenantId,
    String? tenantName,
    String? role,
    List<TenantMembershipItem>? availableTenants,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      role: role ?? this.role,
      availableTenants: availableTenants ?? this.availableTenants,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
