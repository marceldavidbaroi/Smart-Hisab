import 'package:flutter/foundation.dart';

enum AuthStatus {
  initial,
  loading,
  unauthenticated,
  authenticatedNoTenant,
  authenticatedWithTenant,
  error,
}

@immutable
class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? userEmail;
  final String? tenantId;
  final String? tenantName;
  final String? role; // 'owner' or 'manager'
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.userEmail,
    this.tenantId,
    this.tenantName,
    this.role,
    this.errorMessage,
  });

  bool get isLoading => status == AuthStatus.initial || status == AuthStatus.loading;
  bool get isAuthenticated =>
      status == AuthStatus.authenticatedNoTenant ||
      status == AuthStatus.authenticatedWithTenant;
  bool get hasTenant => status == AuthStatus.authenticatedWithTenant;

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? userEmail,
    String? tenantId,
    String? tenantName,
    String? role,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      role: role ?? this.role,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
