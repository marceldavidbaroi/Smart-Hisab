import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/cashbook_entry.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_safe_area.dart';
import '../cashbook/bazar_note_detail_screen.dart';
import '../cashbook/cashbook_notifier.dart';
import '../settings/vendors_notifier.dart';
import '../settings/vendors_screen.dart';
import 'widgets/bazar_cards.dart';

class BazarScreen extends ConsumerStatefulWidget {
  const BazarScreen({super.key});

  @override
  ConsumerState<BazarScreen> createState() => _BazarScreenState();
}

class _BazarScreenState extends ConsumerState<BazarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vendorsNotifierProvider.notifier).fetchVendors();
      ref.read(cashbookNotifierProvider.notifier).fetchCashbookEntries();
    });
  }

  void _openBazarNoteScreen(BuildContext context, {CashbookEntry? existingNote}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BazarNoteDetailScreen(existingNote: existingNote),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

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

    return AppSafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(vendorsNotifierProvider.notifier).fetchVendors();
          await ref.read(cashbookNotifierProvider.notifier).fetchCashbookEntries();
        },
        color: AppColors.primary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bazar & Suppliers',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'দৈনিক বাজারের ফর্দ ও মহাজনদের খাতা',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.plus, size: 18, color: Colors.white),
                    ),
                    onPressed: () => _openBazarNoteScreen(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Suppliers Directory Banner
              BazarVendorBanner(
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

              // Section Title: Bazar Fard
              Text(
                'Bazar Fard (বাজারের ফর্দ)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 10),

              // Notes Area
              Expanded(
                child: notes.isEmpty
                    ? _buildEmptyNotes(context, isDark)
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          // Today's Active Note Card
                          if (todayNote != null) ...[
                            TodayFardCard(
                              note: todayNote,
                              isDark: isDark,
                              onTap: () => _openBazarNoteScreen(context, existingNote: todayNote),
                              onDelete: () => ref.read(cashbookNotifierProvider.notifier).deleteEntry(todayNote.id),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Past Notes Header & List
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
                              child: BazarNoteCard(
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
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyNotes(BuildContext context, bool isDark) {
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
                color: AppColors.info.withValues(alpha: 0.15),
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
