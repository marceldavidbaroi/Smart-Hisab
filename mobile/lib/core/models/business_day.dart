import 'package:flutter/foundation.dart';

/// Status enum for Business Day lifecycle
enum BusinessDayStatus { open, closed }

/// Model representing a Business Day session
@immutable
class BusinessDay {
  final String dayId;
  final String tenantId;
  final DateTime date;
  final BusinessDayStatus status;
  final double openingCash;
  final double totalInflows;
  final double totalOutflows;
  final double expectedCash;
  final double? actualClosingCash;
  final double? variance;
  final String? notes;
  final int todayMeals;
  final double todayCash;
  final double todayBaki;
  final double totalBakiOutstanding;

  const BusinessDay({
    required this.dayId,
    required this.tenantId,
    required this.date,
    required this.status,
    required this.openingCash,
    this.totalInflows = 0.0,
    this.totalOutflows = 0.0,
    this.expectedCash = 0.0,
    this.actualClosingCash,
    this.variance,
    this.notes,
    this.todayMeals = 0,
    this.todayCash = 0.0,
    this.todayBaki = 0.0,
    this.totalBakiOutstanding = 0.0,
  });

  bool get isOpen => status == BusinessDayStatus.open;

  factory BusinessDay.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'closed';
    return BusinessDay(
      dayId: json['day_id'] ?? json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: statusStr == 'open'
          ? BusinessDayStatus.open
          : BusinessDayStatus.closed,
      openingCash: (json['opening_cash'] as num?)?.toDouble() ?? 0.0,
      totalInflows: (json['total_inflows'] as num?)?.toDouble() ?? 0.0,
      totalOutflows: (json['total_outflows'] as num?)?.toDouble() ?? 0.0,
      expectedCash: (json['expected_cash'] as num?)?.toDouble() ?? 0.0,
      actualClosingCash: (json['actual_closing_cash'] as num?)?.toDouble(),
      variance: (json['variance'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      todayMeals: (json['today_meals'] as num?)?.toInt() ?? 0,
      todayCash: (json['today_cash'] as num?)?.toDouble() ?? 0.0,
      todayBaki: (json['today_baki'] as num?)?.toDouble() ?? 0.0,
      totalBakiOutstanding:
          (json['total_baki_outstanding'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_id': dayId,
      'tenant_id': tenantId,
      'date': date.toIso8601String(),
      'status': status.name,
      'opening_cash': openingCash,
      'total_inflows': totalInflows,
      'total_outflows': totalOutflows,
      'expected_cash': expectedCash,
      'actual_closing_cash': actualClosingCash,
      'variance': variance,
      'notes': notes,
      'today_meals': todayMeals,
      'today_cash': todayCash,
      'today_baki': todayBaki,
      'total_baki_outstanding': totalBakiOutstanding,
    };
  }

  BusinessDay copyWith({
    String? dayId,
    String? tenantId,
    DateTime? date,
    BusinessDayStatus? status,
    double? openingCash,
    double? totalInflows,
    double? totalOutflows,
    double? expectedCash,
    double? actualClosingCash,
    double? variance,
    String? notes,
    int? todayMeals,
    double? todayCash,
    double? todayBaki,
    double? totalBakiOutstanding,
  }) {
    return BusinessDay(
      dayId: dayId ?? this.dayId,
      tenantId: tenantId ?? this.tenantId,
      date: date ?? this.date,
      status: status ?? this.status,
      openingCash: openingCash ?? this.openingCash,
      totalInflows: totalInflows ?? this.totalInflows,
      totalOutflows: totalOutflows ?? this.totalOutflows,
      expectedCash: expectedCash ?? this.expectedCash,
      actualClosingCash: actualClosingCash ?? this.actualClosingCash,
      variance: variance ?? this.variance,
      notes: notes ?? this.notes,
      todayMeals: todayMeals ?? this.todayMeals,
      todayCash: todayCash ?? this.todayCash,
      todayBaki: todayBaki ?? this.todayBaki,
      totalBakiOutstanding:
          totalBakiOutstanding ?? this.totalBakiOutstanding,
    );
  }
}

/// Data class representing the recap summary of yesterday's / last closed business day
@immutable
class LastClosedDayRecap {
  final DateTime closedAt;
  final double openingCash;
  final double closingCash;
  final double expectedCash;
  final double variance;
  final int totalMeals;
  final double totalInflows;
  final String? notes;

  const LastClosedDayRecap({
    required this.closedAt,
    required this.openingCash,
    required this.closingCash,
    required this.expectedCash,
    required this.variance,
    required this.totalMeals,
    required this.totalInflows,
    this.notes,
  });

  bool get isBalanced => variance.abs() < 0.01;

  factory LastClosedDayRecap.fromJson(Map<String, dynamic> json) {
    return LastClosedDayRecap(
      closedAt: json['closed_at'] != null
          ? DateTime.tryParse(json['closed_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      openingCash: (json['opening_cash'] as num?)?.toDouble() ?? 0.0,
      closingCash: (json['closing_cash'] as num?)?.toDouble() ?? 0.0,
      expectedCash: (json['expected_cash'] as num?)?.toDouble() ?? 0.0,
      variance: (json['variance'] as num?)?.toDouble() ?? 0.0,
      totalMeals: (json['total_meals'] as num?)?.toInt() ?? 0,
      totalInflows: (json['total_inflows'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'closed_at': closedAt.toIso8601String(),
      'opening_cash': openingCash,
      'closing_cash': closingCash,
      'expected_cash': expectedCash,
      'variance': variance,
      'total_meals': totalMeals,
      'total_inflows': totalInflows,
      'notes': notes,
    };
  }
}

