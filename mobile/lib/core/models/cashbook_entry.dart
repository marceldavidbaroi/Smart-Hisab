import 'package:flutter/foundation.dart';

/// Data model representing a Cashbook entry / Day transaction entry.
@immutable
class CashbookEntry {
  final String id;
  final String tenantId;
  final String? businessDayId;
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
    required this.type,
    required this.title,
    required this.category,
    required this.amount,
    this.notes,
    required this.createdAt,
  });

  factory CashbookEntry.fromJson(Map<String, dynamic> json) {
    return CashbookEntry(
      id: json['id'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      businessDayId: json['business_day_id'] as String?,
      type: json['type'] as String? ?? 'expense',
      title: json['title'] as String? ?? 'Transaction',
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
      type: type ?? this.type,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
