import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/cashbook_entry.dart';
import '../../../core/utils/formatters.dart';
import '../../settings/vendors_notifier.dart';
import '../../settings/vendors_screen.dart';
import '../bazar_note_detail_screen.dart';
import '../cashbook_notifier.dart';

class BazarHubView extends ConsumerWidget {
  const BazarHubView({super.key});

  void _openBazarNoteScreen(BuildContext context, {CashbookEntry? existingNote}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BazarNoteDetailScreen(existingNote: existingNote),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cashbookState = ref.watch(cashbookNotifierProvider);
    final vendorsState = ref.watch(vendorsNotifierProvider);

    // Filter notes for Bazar shopping lists
    final notes = cashbookState.entries.where((e) => e.type == 'note').toList();
    final today = DateTime.now();
    
    // Find today's active fard
    final todayNote = notes.where((n) =>
      n.createdAt.year == today.year &&
      n.createdAt.month == today.month &&
      n.createdAt.day == today.day
    ).firstOrNull;

    // Past notes excluding today's primary note
    final pastNotes = todayNote != null
        ? notes.where((n) => n.id != todayNote.id).toList()
        : notes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Suppliers Directory Banner / Button
        _BazarActionButton(
          title: 'Suppliers & Vendors (মহাজনদের খাতা)',
          subtitle: '${vendorsState.vendors.length} vendors • ${AppFormatters.formatBdt(vendorsState.totalVendorDebt)} Total Due',
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
        const SizedBox(height: 16),

        // Section Title: Bazar Fard with Top '+' Create Icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bazar Fard (বাজারের ফর্দ)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.plus, size: 16, color: AppColors.primary),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _openBazarNoteScreen(context),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Notes Area (Today's note on top + history list)
        Expanded(
          child: notes.isEmpty
              ? _buildEmptyNotes(context, ref, isDark)
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // Today's Active Note Card (Prominent & Tap to Open)
                    if (todayNote != null) ...[
                      _TodayFardCard(
                        note: todayNote,
                        isDark: isDark,
                        onTap: () => _openBazarNoteScreen(context, existingNote: todayNote),
                        onDelete: () => ref.read(cashbookNotifierProvider.notifier).deleteEntry(todayNote.id),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Past Notes Header
                    if (pastNotes.isNotEmpty) ...[
                      Text(
                        'Past Market Notes (${pastNotes.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...pastNotes.map((note) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _BazarNoteCard(
                          note: note,
                          isDark: isDark,
                          onTap: () => _openBazarNoteScreen(context, existingNote: note),
                          onDelete: () => ref.read(cashbookNotifierProvider.notifier).deleteEntry(note.id),
                        ),
                      )),
                    ],
                  ],
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
              onPressed: () => _openBazarNoteScreen(context),
              icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
              label: const Text(
                'Create Today\'s Bazar Fard',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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

class _TodayFardCard extends StatelessWidget {
  final CashbookEntry note;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TodayFardCard({
    required this.note,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withAlpha(120),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(isDark ? 30 : 15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.shoppingBag, color: AppColors.primary, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Today\'s Fard (আজকের ফর্দ)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.edit2, size: 11, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
              if (note.title.isNotEmpty && note.title != 'Day Note' && note.title != 'Bazar Fard') ...[
                const SizedBox(height: 10),
                Text(
                  note.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
              if (note.notes != null && note.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.bgDark : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    note.notes!,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Created at ${AppFormatters.formatTimeOnly(note.createdAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
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
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BazarNoteCard({
    required this.note,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(14),
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
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(LucideIcons.fileText, color: AppColors.info, size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppFormatters.formatDateShort(note.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 15, color: AppColors.danger),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
              if (note.notes != null && note.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  note.notes!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

