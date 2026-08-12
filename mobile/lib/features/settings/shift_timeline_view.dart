import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'shifts_notifier.dart';

class ShiftTimelineView extends StatelessWidget {
  final List<CanteenShift> shifts;

  const ShiftTimelineView({super.key, required this.shifts});

  int _parseTimeToMinutes(String timeStr) {
    try {
      final str = timeStr.trim();
      final isPm = str.toUpperCase().contains('PM');
      final isAm = str.toUpperCase().contains('AM');
      final cleanStr = str.replaceAll(RegExp(r'[^\d:]'), '');
      final timeParts = cleanStr.split(':');
      if (timeParts.isEmpty) return 0;
      int hour = int.parse(timeParts[0]);
      final minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;

      if (isPm && hour < 12) hour += 12;
      if (isAm && hour == 12) hour = 0;

      return (hour * 60 + minute).clamp(0, 1440);
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeShifts = shifts.where((s) => s.isActive).toList();

    // Check overlaps
    bool hasOverlap = false;
    for (int i = 0; i < activeShifts.length; i++) {
      final s1Start = _parseTimeToMinutes(activeShifts[i].startTime);
      final s1End = _parseTimeToMinutes(activeShifts[i].endTime);
      for (int j = i + 1; j < activeShifts.length; j++) {
        final s2Start = _parseTimeToMinutes(activeShifts[j].startTime);
        final s2End = _parseTimeToMinutes(activeShifts[j].endTime);
        if (s1Start < s2End && s1End > s2Start) {
          hasOverlap = true;
          break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasOverlap
              ? AppColors.danger
              : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
          width: hasOverlap ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timeline, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Daily Operating Timeline',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasOverlap
                      ? AppColors.danger.withValues(alpha: 0.15)
                      : AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasOverlap ? 'Overlap Detected!' : '${activeShifts.length} Active Shifts',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: hasOverlap ? AppColors.danger : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Timeline Bar Track
          SizedBox(
            height: 36,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;
                return Stack(
                  children: [
                    // Background Track (24 hours)
                    Container(
                      width: trackWidth,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Shift Blocks
                    ...activeShifts.map((shift) {
                      final startMin = _parseTimeToMinutes(shift.startTime);
                      var endMin = _parseTimeToMinutes(shift.endTime);
                      if (endMin <= startMin && endMin != 0) {
                        endMin = 1440; // Handle overnight/midnight end
                      }

                      final leftPos = (startMin / 1440.0) * trackWidth;
                      final rightPos = (endMin / 1440.0) * trackWidth;
                      final blockWidth = (rightPos - leftPos).clamp(16.0, trackWidth - leftPos);

                      return Positioned(
                        left: leftPos,
                        width: blockWidth,
                        top: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            shift.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Hour Scale Ticks
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12 AM', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
              Text('06 AM', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
              Text('12 PM', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
              Text('06 PM', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
              Text('12 AM', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
            ],
          ),
        ],
      ),
    );
  }
}
