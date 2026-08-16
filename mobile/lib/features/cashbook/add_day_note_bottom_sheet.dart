import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';

class AddDayNoteBottomSheet extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final Function({
    required String title,
    required String content,
  }) onSubmit;

  const AddDayNoteBottomSheet({
    super.key,
    this.initialTitle,
    this.initialContent,
    required this.onSubmit,
  });

  static void show(
    BuildContext context, {
    String? initialTitle,
    String? initialContent,
    required Function({
      required String title,
      required String content,
    }) onSubmit,
  }) {
    CustomModalBottomSheet.show(
      context: context,
      title: initialTitle != null ? 'Edit Bazar Note / Fard' : 'Add Bazar Note / Fard',
      child: AddDayNoteBottomSheet(
        initialTitle: initialTitle,
        initialContent: initialContent,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<AddDayNoteBottomSheet> createState() => _AddDayNoteBottomSheetState();
}

class _AddDayNoteBottomSheetState extends State<AddDayNoteBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    widget.onSubmit(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title Input
          TextFormField(
            controller: _titleController,
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Note Title / Topic',
              hintText: 'e.g. Market Shopping List for Tomorrow',
              hintStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 14),
              labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              filled: true,
              fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
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
          const SizedBox(height: 14),

          // Content Input
          TextFormField(
            controller: _contentController,
            maxLines: 4,
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Note Content / Items *',
              hintText: 'e.g. Need 10kg Minikit Rice, 5L Soyabean Oil, 2kg Salt...',
              hintStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 14),
              labelStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              filled: true,
              fillColor: isDark ? AppColors.bgDark : AppColors.bgLight,
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
                return 'Please enter note content';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Save Note Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save Day Note',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
