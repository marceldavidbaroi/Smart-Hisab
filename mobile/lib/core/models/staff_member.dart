import 'package:flutter/foundation.dart';

enum StaffRole { owner, manager, staff }

@immutable
class StaffMember {
  final String id;
  final String name;
  final StaffRole role;
  final String? pinCode;
  final String? phone;
  final String? avatarUrl;
  final double monthlySalary;
  final double totalPaidThisMonth;
  final DateTime? createdAt;

  const StaffMember({
    required this.id,
    required this.name,
    this.role = StaffRole.staff,
    this.pinCode,
    this.phone,
    this.avatarUrl,
    this.monthlySalary = 0.0,
    this.totalPaidThisMonth = 0.0,
    this.createdAt,
  });

  double get unpaidBalance => (monthlySalary - totalPaidThisMonth).clamp(0.0, double.infinity);

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? 'staff';
    StaffRole roleEnum;
    switch (roleStr.toLowerCase()) {
      case 'owner':
        roleEnum = StaffRole.owner;
        break;
      case 'manager':
        roleEnum = StaffRole.manager;
        break;
      default:
        roleEnum = StaffRole.staff;
    }

    return StaffMember(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      role: roleEnum,
      pinCode: json['pin_code'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      monthlySalary: (json['monthly_salary'] as num?)?.toDouble() ?? 0.0,
      totalPaidThisMonth: (json['total_paid_this_month'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.name,
      'pin_code': pinCode,
      'phone': phone,
      'avatar_url': avatarUrl,
      'monthly_salary': monthlySalary,
      'total_paid_this_month': totalPaidThisMonth,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  StaffMember copyWith({
    String? id,
    String? name,
    StaffRole? role,
    String? pinCode,
    String? phone,
    String? avatarUrl,
    double? monthlySalary,
    double? totalPaidThisMonth,
    DateTime? createdAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      pinCode: pinCode ?? this.pinCode,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      totalPaidThisMonth: totalPaidThisMonth ?? this.totalPaidThisMonth,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

