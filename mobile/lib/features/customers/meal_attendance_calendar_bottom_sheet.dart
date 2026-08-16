import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/customer.dart';
import '../../core/services/supabase_service.dart';
import 'customers_notifier.dart';
import 'void_transaction_bottom_sheet.dart';

class MealAttendanceCalendarBottomSheet extends ConsumerStatefulWidget {
  final Customer customer;

  const MealAttendanceCalendarBottomSheet({
    super.key,
    required this.customer,
  });

  static Future<void> show(BuildContext context, Customer customer) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MealAttendanceCalendarBottomSheet(customer: customer),
    );
  }

  @override
  ConsumerState<MealAttendanceCalendarBottomSheet> createState() =>
      _MealAttendanceCalendarBottomSheetState();
}

class _MealAttendanceCalendarBottomSheetState
    extends ConsumerState<MealAttendanceCalendarBottomSheet> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customersNotifier = ref.watch(customersNotifierProvider.notifier);
    final customersState = ref.watch(customersNotifierProvider);

    final attendanceSet = customersNotifier.getCustomerAttendanceDates(widget.customer.id);
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final isTodayPresent = attendanceSet.contains(todayKey) || customersState.markedCustomerIds.contains(widget.customer.id);

    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final leadingEmptyDays = (firstDayOfMonth.weekday - 1) % 7; // Monday = 1

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), // Rule #3
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle Bar (Rule #3)
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header Title
          Row(
            children: [
              const Icon(LucideIcons.calendarCheck2, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Meal Attendance Calendar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Select present meal dates for ${widget.customer.name}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),

          // Quick Action: "Mark Today as Present" Hero Button
          ElevatedButton.icon(
            onPressed: () async {
              if (isTodayPresent) {
                // Revert flow for today
                Map<String, dynamic>? matchingEntry;
                try {
                  final walletRes = await SupabaseService.client
                      .from('customer_wallets')
                      .select('id')
                      .eq('customer_id', widget.customer.id)
                      .maybeSingle();
                  if (walletRes != null && walletRes['id'] != null) {
                    final walletId = walletRes['id'] as String;
                    final entriesRes = await SupabaseService.client
                        .from('wallet_entries')
                        .select('*')
                        .eq('wallet_id', walletId)
                        .gte('created_at', '${todayKey}T00:00:00')
                        .lte('created_at', '${todayKey}T23:59:59')
                        .order('created_at', ascending: false);

                    final list = entriesRes as List;
                    if (list.isNotEmpty) {
                      matchingEntry = Map<String, dynamic>.from(list.first as Map);
                    }
                  }
                } catch (e) {
                  debugPrint('Error finding today attendance entry: $e');
                }

                if (!context.mounted) return;
                final voided = await VoidTransactionBottomSheet.show(
                  context,
                  customer: widget.customer,
                  entry: matchingEntry ?? {
                    'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
                    'type': 'charge',
                    'amount': customersState.activeShiftRate > 0 ? customersState.activeShiftRate : 80.0,
                    'notes': 'Meal Attendance ($todayKey)',
                    'created_at': today.toIso8601String(),
                  },
                );
                if (context.mounted && voided == true) {
                  await customersNotifier.fetchCustomers();
                }
              } else {
                await customersNotifier.toggleCustomerAttendanceDate(widget.customer.id, today);
              }
            },
            icon: Icon(
              isTodayPresent ? LucideIcons.checkCircle2 : LucideIcons.plusCircle,
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              isTodayPresent ? 'Today Marked as Present (Tap to void)' : 'Mark Today as Present',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isTodayPresent ? AppColors.success : AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 18),

          // Month Navigation Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.chevronLeft),
                onPressed: _previousMonth,
                tooltip: 'Previous Month',
              ),
              Text(
                _formatMonthYear(_displayedMonth),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.chevronRight),
                onPressed: _nextMonth,
                tooltip: 'Next Month',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Days of Week Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmptyDays + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptyDays) {
                return const SizedBox.shrink();
              }

              final dayNum = index - leadingEmptyDays + 1;
              final date = DateTime(_displayedMonth.year, _displayedMonth.month, dayNum);
              final key = _dateKey(date);
              final isPresent = attendanceSet.contains(key) || (isSameDay(date, today) && isTodayPresent);
              final isTodayDate = _isSameDay(date, today);

              return InkWell(
                onTap: () async {
                  if (isPresent) {
                    // Revert flow: Trigger void transaction bottom sheet
                    Map<String, dynamic>? matchingEntry;
                    try {
                      final walletRes = await SupabaseService.client
                          .from('customer_wallets')
                          .select('id')
                          .eq('customer_id', widget.customer.id)
                          .maybeSingle();
                      if (walletRes != null && walletRes['id'] != null) {
                        final walletId = walletRes['id'] as String;
                        final keyStr = key;
                        final entriesRes = await SupabaseService.client
                            .from('wallet_entries')
                            .select('*')
                            .eq('wallet_id', walletId)
                            .gte('created_at', '${keyStr}T00:00:00')
                            .lte('created_at', '${keyStr}T23:59:59')
                            .order('created_at', ascending: false);

                        final list = entriesRes as List;
                        if (list.isNotEmpty) {
                          matchingEntry = Map<String, dynamic>.from(list.first as Map);
                        }
                      }
                    } catch (e) {
                      debugPrint('Error finding attendance entry for void: $e');
                    }

                    if (matchingEntry != null) {
                      if (!context.mounted) return;
                      final voided = await VoidTransactionBottomSheet.show(
                        context,
                        customer: widget.customer,
                        entry: matchingEntry,
                      );
                      if (context.mounted && voided == true) {
                        await customersNotifier.fetchCustomers();
                      }
                    } else {
                      // Fallback dummy entry construct for voiding if offline/un-synced
                      if (!context.mounted) return;
                      final voided = await VoidTransactionBottomSheet.show(
                        context,
                        customer: widget.customer,
                        entry: {
                          'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
                          'type': 'charge',
                          'amount': customersState.activeShiftRate > 0 ? customersState.activeShiftRate : 80.0,
                          'notes': 'Meal Attendance ($key)',
                          'created_at': date.toIso8601String(),
                        },
                      );
                      if (context.mounted && voided == true) {
                        await customersNotifier.fetchCustomers();
                      }
                    }
                  } else {
                    await customersNotifier.toggleCustomerAttendanceDate(widget.customer.id, date);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isPresent
                        ? AppColors.success
                        : (isTodayDate
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isTodayDate
                          ? AppColors.primary
                          : (isPresent ? AppColors.success : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight)),
                      width: isTodayDate ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isPresent
                              ? Colors.white
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                        ),
                      ),
                      if (isPresent)
                        const Icon(LucideIcons.check, size: 12, color: Colors.white),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Done Action Button
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
