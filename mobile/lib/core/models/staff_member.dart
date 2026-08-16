import 'package:flutter/foundation.dart';

enum StaffRole { owner, manager, staff }

enum SalaryType { daily, monthly }

@immutable
class StaffMember {
  final String id;
  final String name;
  final StaffRole role;
  final SalaryType salaryType;
  final String? pinCode;
  final String? phone;
  final String? avatarUrl;
  final double monthlySalary; // Used for base salary rate (daily rate or monthly rate)
  final double totalPaidThisMonth; // Regular salary paid
  final double totalAdvanceThisMonth; // Advance paid
  final DateTime? createdAt;

  const StaffMember({
    required this.id,
    required this.name,
    this.role = StaffRole.staff,
    this.salaryType = SalaryType.monthly,
    this.pinCode,
    this.phone,
    this.avatarUrl,
    this.monthlySalary = 0.0,
    this.totalPaidThisMonth = 0.0,
    this.totalAdvanceThisMonth = 0.0,
    this.createdAt,
  });

  double get baseSalaryRate => monthlySalary;

  /// Total money drawn so far this month (regular salary + advance)
  double get totalDrawnThisMonth => totalPaidThisMonth + totalAdvanceThisMonth;

  /// Net salary due to be paid (Base salary minus regular payouts and advances)
  double get netSalaryDue => (monthlySalary - totalDrawnThisMonth).clamp(0.0, double.infinity);

  /// If the staff has taken advances greater than earned salary / wages
  double get owesCanteenAmount => (totalDrawnThisMonth - monthlySalary).clamp(0.0, double.infinity);

  bool get owesCanteen => totalDrawnThisMonth > monthlySalary;

  double get unpaidBalance => netSalaryDue;

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

    final salaryTypeStr = json['salary_type'] as String? ?? 'monthly';
    final salaryTypeEnum = salaryTypeStr.toLowerCase() == 'daily' ? SalaryType.daily : SalaryType.monthly;

    return StaffMember(
      id: json['id'] as String? ?? '',
      name: json['full_name'] as String? ?? json['name'] as String? ?? 'Unknown',
      role: roleEnum,
      salaryType: salaryTypeEnum,
      pinCode: json['pin_code'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      monthlySalary: (json['monthly_salary'] as num?)?.toDouble() ?? 0.0,
      totalPaidThisMonth: (json['total_paid_this_month'] as num?)?.toDouble() ?? 0.0,
      totalAdvanceThisMonth: (json['total_advance_this_month'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.name,
      'salary_type': salaryType.name,
      'pin_code': pinCode,
      'phone': phone,
      'avatar_url': avatarUrl,
      'monthly_salary': monthlySalary,
      'total_paid_this_month': totalPaidThisMonth,
      'total_advance_this_month': totalAdvanceThisMonth,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  StaffMember copyWith({
    String? id,
    String? name,
    StaffRole? role,
    SalaryType? salaryType,
    String? pinCode,
    String? phone,
    String? avatarUrl,
    double? monthlySalary,
    double? totalPaidThisMonth,
    double? totalAdvanceThisMonth,
    DateTime? createdAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      salaryType: salaryType ?? this.salaryType,
      pinCode: pinCode ?? this.pinCode,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      totalPaidThisMonth: totalPaidThisMonth ?? this.totalPaidThisMonth,
      totalAdvanceThisMonth: totalAdvanceThisMonth ?? this.totalAdvanceThisMonth,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

