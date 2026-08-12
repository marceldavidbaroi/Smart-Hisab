import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/staff_member.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';

class RecordSalaryPayoutBottomSheet extends StatefulWidget {
  final StaffMember staff;
  final Function({
    required String staffId,
    required double amount,
    required String paymentMode,
    String? notes,
  }) onConfirm;

  const RecordSalaryPayoutBottomSheet({
    super.key,
    required this.staff,
    required this.onConfirm,
  });

  static void show(
    BuildContext context, {
    required StaffMember staff,
    required Function({
      required String staffId,
      required double amount,
      required String paymentMode,
      String? notes,
    }) onConfirm,
  }) {
    CustomModalBottomSheet.show(
      context: context,
      title: 'Salary Payout — ${staff.name}',
      child: RecordSalaryPayoutBottomSheet(staff: staff, onConfirm: onConfirm),
    );
  }

  @override
  State<RecordSalaryPayoutBottomSheet> createState() => _RecordSalaryPayoutBottomSheetState();
}

class _RecordSalaryPayoutBottomSheetState extends State<RecordSalaryPayoutBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final _notesController = TextEditingController();
  String _selectedPaymentMode = 'Cash';
  bool _isSubmitting = false;

  final List<String> _paymentModes = ['Cash', 'bKash', 'Nagad', 'Bank Transfer'];

  @override
  void initState() {
    super.initState();
    // Default payout input to remaining unpaid balance if present, or monthly salary
    final defaultAmt = widget.staff.unpaidBalance > 0
        ? widget.staff.unpaidBalance
        : widget.staff.monthlySalary;
    _amountController = TextEditingController(
      text: defaultAmt > 0 ? defaultAmt.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;

    widget.onConfirm(
      staffId: widget.staff.id,
      amount: amount,
      paymentMode: _selectedPaymentMode,
      notes: notes,
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monthly Salary', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                    Text('৳${widget.staff.monthlySalary.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Unpaid Balance', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                    Text(
                      '৳${widget.staff.unpaidBalance.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: widget.staff.unpaidBalance > 0 ? AppColors.danger : AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Payout Amount (৳) *',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter payout amount';
              final amt = double.tryParse(v.trim());
              if (amt == null || amt <= 0) return 'Enter valid positive amount';
              return null;
            },
          ),
          const SizedBox(height: 14),
          const Text('Payment Mode', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _paymentModes.map((mode) {
              final isSelected = _selectedPaymentMode == mode;
              return ChoiceChip(
                label: Text(mode, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
                selected: isSelected,
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.bgDark,
                onSelected: (val) {
                  if (val) setState(() => _selectedPaymentMode = mode);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _notesController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Notes / Reference (Optional)',
              labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Confirm Payout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
