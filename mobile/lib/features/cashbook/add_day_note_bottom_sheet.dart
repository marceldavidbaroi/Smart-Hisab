import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';

class AddDayNoteBottomSheet extends StatefulWidget {
  final Function({
    required String title,
    required String content,
  }) onSubmit;

  const AddDayNoteBottomSheet({
    super.key,
    required this.onSubmit,
  });

  static void show(
    BuildContext context, {
    required Function({
      required String title,
      required String content,
    }) onSubmit,
  }) {
    CustomModalBottomSheet.show(
      context: context,
      title: 'Add Day Note / Market List',
      child: AddDayNoteBottomSheet(onSubmit: onSubmit),
    );
  }

  @override
  State<AddDayNoteBottomSheet> createState() => _AddDayNoteBottomSheetState();
}

class _AddDayNoteBottomSheetState extends State<AddDayNoteBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

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
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title Input
          TextFormField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Note Title / Topic',
              hintText: 'e.g. Market Shopping List for Tomorrow',
              hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorderDark),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Content Input
          TextFormField(
            controller: _contentController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Note Content / Items *',
              hintText: 'e.g. Need 10kg Minikit Rice, 5L Soyabean Oil, 2kg Salt...',
              hintStyle: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.cardBorderDark),
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
