import 'package:flutter/foundation.dart';

/// Data model representing a Canteen Account / Business Money Channel (Canteen Wallet)
@immutable
class CanteenAccount {
  final String id;
  final String tenantId;
  final String name;
  final String accountType; // 'cash_drawer' | 'mobile_money' | 'bank' | 'safe'
  final String? accountNumber;
  final double currentBalance;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CanteenAccount({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.accountType,
    this.accountNumber,
    this.currentBalance = 0.0,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CanteenAccount.fromJson(Map<String, dynamic> json) {
    return CanteenAccount(
      id: json['id'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Account',
      accountType: json['account_type'] as String? ?? 'cash_drawer',
      accountNumber: json['account_number'] as String?,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'account_type': accountType,
      'account_number': accountNumber,
      'current_balance': currentBalance,
      'is_default': isDefault,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CanteenAccount copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? accountType,
    String? accountNumber,
    double? currentBalance,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CanteenAccount(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      accountNumber: accountNumber ?? this.accountNumber,
      currentBalance: currentBalance ?? this.currentBalance,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
