import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/cashbook_entry.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_safe_area.dart';
import 'cashbook_notifier.dart';

class BazarNoteDetailScreen extends ConsumerStatefulWidget {
  final CashbookEntry? existingNote; // null means create new

  const BazarNoteDetailScreen({
    super.key,
    this.existingNote,
  });

  @override
  ConsumerState<BazarNoteDetailScreen> createState() => _BazarNoteDetailScreenState();
}

class _BazarNoteDetailScreenState extends ConsumerState<BazarNoteDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late DateTime _selectedDate;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final note = widget.existingNote;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.notes ?? '');
    _selectedDate = note?.createdAt ?? DateTime.now();
    // If it's a new note, start in editing mode; otherwise start in safe Preview mode
    _isEditing = note == null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final title = _titleController.text.trim().isEmpty ? 'Bazar Fard' : _titleController.text.trim();
    final content = _contentController.text.trim();

    if (widget.existingNote != null) {
      final success = await ref.read(cashbookNotifierProvider.notifier).updateDayNote(
            id: widget.existingNote!.id,
            title: title,
            content: content,
            date: _selectedDate,
          );
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditing = false;
        });
        if (success) {
          NotificationService.showSuccess('Bazar note updated');
        }
      }
    } else {
      final success = await ref.read(cashbookNotifierProvider.notifier).addDayNote(
            title: title,
            content: content,
            date: _selectedDate,
          );
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          NotificationService.showSuccess('Bazar shopping note saved');
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          title: const Text('Delete Bazar Note?'),
          content: const Text('Are you sure you want to delete this shopping list?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && widget.existingNote != null && mounted) {
      await ref.read(cashbookNotifierProvider.notifier).deleteEntry(widget.existingNote!.id);
      if (mounted) {
        NotificationService.showSuccess('Bazar note deleted');
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNewNote = widget.existingNote == null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: AppSafeArea(
        child: Column(
          children: [
            // Top App Bar Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isNewNote
                          ? 'New Bazar Fard'
                          : (_isEditing ? 'Edit Bazar Note' : 'Bazar Note (Preview)'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  if (!isNewNote) ...[
                    // Toggle Preview vs Edit Mode Button
                    IconButton(
                      icon: Icon(
                        _isEditing ? LucideIcons.eye : LucideIcons.edit3,
                        color: AppColors.primary,
                      ),
                      tooltip: _isEditing ? 'Preview Mode' : 'Edit Note',
                      onPressed: () {
                        setState(() => _isEditing = !_isEditing);
                      },
                    ),
                    // Delete Button
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: AppColors.danger),
                      tooltip: 'Delete Note',
                      onPressed: _confirmDelete,
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),

            // Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _isEditing
                    ? _buildEditForm(isDark)
                    : _buildPreviewMode(isDark),
              ),
            ),

            // Bottom Action Bar (in Edit Mode)
            if (_isEditing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (!isNewNote)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Cancel edit and revert to saved note
                            setState(() {
                              _titleController.text = widget.existingNote?.title ?? '';
                              _contentController.text = widget.existingNote?.notes ?? '';
                              _isEditing = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    if (!isNewNote) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveNote,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(LucideIcons.save, size: 18, color: Colors.white),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save Fard',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Selector Row
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.calendar, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Note Date:',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppFormatters.formatDateShort(_selectedDate),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title Input
          TextFormField(
            controller: _titleController,
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              labelText: 'Topic / Title (Optional)',
              hintText: 'e.g. Morning Bazar (আজকের বাজার)',
              hintStyle: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 14,
              ),
              labelStyle: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              filled: true,
              fillColor: isDark ? AppColors.cardDark : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Content Input (Large multi-line note)
          TextFormField(
            controller: _contentController,
            maxLines: 15,
            minLines: 8,
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              fontSize: 16,
              height: 1.5,
            ),
            decoration: InputDecoration(
              labelText: 'Bazar Items / Fard *',
              hintText: '1. Minikit Rice 2 sacks (৫০ কেজি)\n2. Chicken 30kg\n3. Soybean Oil 10L\n4. Potatoes 20kg, Onions 10kg\n5. Green Chili & Coriander...',
              hintStyle: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 14,
              ),
              alignLabelWithHint: true,
              filled: true,
              fillColor: isDark ? AppColors.cardDark : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter grocery list / items';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewMode(bool isDark) {
    final note = widget.existingNote;
    if (note == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Banner to prevent accidental edits
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.info.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.info.withAlpha(50)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Preview Mode: Protected from accidental touches in the market.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          note.title.isNotEmpty ? note.title : 'Bazar Fard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Saved on ${AppFormatters.formatDateTime(note.createdAt)}',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 16),

        // Items Content Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
            ),
          ),
          child: SelectableText(
            note.notes ?? 'No items listed.',
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }
}
