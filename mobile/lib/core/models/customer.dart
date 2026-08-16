import 'package:flutter/foundation.dart';

/// Data class representing a Customer profile and wallet state.
@immutable
class Customer {
  final String id;
  final String tenantId;
  final String name;
  final String? phone;
  final String? address;
  final String? institution;
  final bool isActive;
  final double currentBalance;
  final DateTime? createdAt;

  final List<String> activeMeals;

  const Customer({
    required this.id,
    required this.tenantId,
    required this.name,
    this.phone,
    this.address,
    this.institution,
    this.isActive = true,
    this.currentBalance = 0.0,
    this.createdAt,
    this.activeMeals = const [],
  });

  /// Factory constructor to create a [Customer] from a Supabase JSON payload.
  factory Customer.fromJson(Map<String, dynamic> json) {
    // Handle nested customer_wallets if present, or top-level current_balance / balance
    double balance = 0.0;
    if (json['customer_wallets'] != null &&
        json['customer_wallets'] is Map<String, dynamic>) {
      balance = (json['customer_wallets']['current_balance'] as num?)?.toDouble() ?? 0.0;
    } else if (json['current_balance'] != null) {
      balance = (json['current_balance'] as num?)?.toDouble() ?? 0.0;
    } else if (json['balance'] != null) {
      balance = (json['balance'] as num?)?.toDouble() ?? 0.0;
    }

    List<String> meals = const [];
    if (json['active_meals'] != null && json['active_meals'] is List) {
      meals = List<String>.from(json['active_meals'] as List);
    } else if (json['subscribed_shifts'] != null && json['subscribed_shifts'] is List) {
      meals = List<String>.from(json['subscribed_shifts'] as List);
    }

    return Customer(
      id: json['id'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      institution: json['institution'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      currentBalance: balance,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      activeMeals: meals,
    );
  }

  /// Converts this [Customer] instance to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'phone': phone,
      'address': address,
      'institution': institution,
      'is_active': isActive,
      'current_balance': currentBalance,
      'created_at': createdAt?.toIso8601String(),
      'active_meals': activeMeals,
    };
  }

  /// Creates a copy of this [Customer] with given fields replaced.
  Customer copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? phone,
    String? address,
    String? institution,
    bool? isActive,
    double? currentBalance,
    DateTime? createdAt,
    List<String>? activeMeals,
  }) {
    return Customer(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      institution: institution ?? this.institution,
      isActive: isActive ?? this.isActive,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
      activeMeals: activeMeals ?? this.activeMeals,
    );
  }
}
