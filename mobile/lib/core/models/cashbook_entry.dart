import 'package:flutter/foundation.dart';

/// Data model representing a Cashbook entry / Day transaction entry.
@immutable
class CashbookEntry {
  final String id;
  final String tenantId;
  final String? businessDayId;
  final String? accountId;
  final String? accountName;
  final String type; // 'income' | 'expense' | 'note'
  final String title;
  final String category;
  final double amount;
  final String? notes;
  final DateTime createdAt;

  const CashbookEntry({
    required this.id,
    required this.tenantId,
    this.businessDayId,
    this.accountId,
    this.accountName,
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    this.notes,
    required this.createdAt,
  });

  factory CashbookEntry.fromJson(Map<String, dynamic> json) {
    // Check if category or entry_type is mapped from Supabase day_entries vs local
    final rawType = json['type'] ?? json['entry_type'];
    final normalizedType = rawType == 'inflow'
        ? 'income'
        : (rawType == 'outflow' ? 'expense' : (rawType as String? ?? 'expense'));

    return CashbookEntry(
      id: json['id'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      businessDayId: json['business_day_id'] as String?,
      accountId: json['canteen_account_id'] as String? ?? json['account_id'] as String?,
      accountName: json['canteen_accounts'] != null && json['canteen_accounts'] is Map
          ? (json['canteen_accounts']['name'] as String?)
          : json['account_name'] as String?,
      type: normalizedType,
      title: json['title'] as String? ?? json['notes'] as String? ?? 'Transaction',
      category: json['category'] as String? ?? 'General',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'business_day_id': businessDayId,
      'canteen_account_id': accountId,
      'account_name': accountName,
      'type': type,
      'title': title,
      'category': category,
      'amount': amount,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CashbookEntry copyWith({
    String? id,
    String? tenantId,
    String? businessDayId,
    String? accountId,
    String? accountName,
    String? type,
    String? title,
    String? category,
    double? amount,
    String? notes,
    DateTime? createdAt,
  }) {
    return CashbookEntry(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      businessDayId: businessDayId ?? this.businessDayId,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      type: type ?? this.type,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
