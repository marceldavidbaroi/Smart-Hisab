import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/cashbook_entry.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/formatters.dart';
import '../../settings/vendors_notifier.dart';
import '../../settings/vendors_screen.dart';
import '../add_day_note_bottom_sheet.dart';
import '../cashbook_notifier.dart';

class BazarHubView extends ConsumerWidget {
  const BazarHubView({super.key});

  void _showAddBazarNoteModal(BuildContext context, WidgetRef ref) {
    AddDayNoteBottomSheet.show(
      context,
      onSubmit: ({
        required String title,
        required String content,
      }) async {
        final success = await ref.read(cashbookNotifierProvider.notifier).addDayNote(
              title: title,
              content: content,
            );
        if (success && context.mounted) {
          NotificationService.showSuccess('Bazar shopping note saved');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cashbookState = ref.watch(cashbookNotifierProvider);
    final vendorsState = ref.watch(vendorsNotifierProvider);

    // Filter notes for Bazar shopping lists
    final notes = cashbookState.entries.where((e) => e.type == 'note').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Two Primary Navigation / Action Buttons
        Row(
          children: [
            Expanded(
              child: _BazarActionButton(
                title: 'Suppliers & Vendors',
                subtitle: '${vendorsState.vendors.length} vendors',
                icon: LucideIcons.store,
                color: AppColors.primary,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VendorsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BazarActionButton(
                title: 'New Bazar Note',
                subtitle: 'Shopping list',
                icon: LucideIcons.filePlus,
                color: AppColors.info,
                isDark: isDark,
                onTap: () => _showAddBazarNoteModal(context, ref),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Section Title: Bazar & Shopping Notes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bazar & Market Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            Text(
              '${notes.length} saved',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Notes List or Empty State
        Expanded(
          child: notes.isEmpty
              ? _buildEmptyNotes(context, ref, isDark)
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: notes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _BazarNoteCard(
                      note: note,
                      isDark: isDark,
                      onDelete: () => ref.read(cashbookNotifierProvider.notifier).deleteEntry(note.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyNotes(BuildContext context, WidgetRef ref, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.fileText, color: AppColors.info, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              'No Bazar Notes Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create shopping lists for groceries, rice, spices, vegetables, or market reminders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddBazarNoteModal(context, ref),
              icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
              label: const Text(
                'Add Bazar Note',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BazarActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _BazarActionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BazarNoteCard extends StatelessWidget {
  final CashbookEntry note;
  final bool isDark;
  final VoidCallback onDelete;

  const _BazarNoteCard({
    required this.note,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.fileText, color: AppColors.info, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    note.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDelete,
              ),
            ],
          ),
          if (note.notes != null && note.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note.notes!,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            AppFormatters.formatTimeOnly(note.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
