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
    required String payoutType,
    String? accountId,
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
      required String payoutType,
      String? accountId,
      String? notes,
    }) onConfirm,
  }) {
    CustomModalBottomSheet.show(
      context: context,
      title: 'Pay Staff — ${staff.name}',
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
  String _payoutType = 'regular_salary'; // 'regular_salary' or 'advance'
  String _selectedPaymentMode = 'Cash Drawer';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _paymentAccounts = [
    {'name': 'Cash Drawer', 'mode': 'Cash', 'icon': Icons.point_of_sale_rounded},
    {'name': 'bKash / Mobile', 'mode': 'bKash', 'icon': Icons.phone_android_rounded},
    {'name': 'Bank Transfer', 'mode': 'Bank', 'icon': Icons.account_balance_rounded},
    {'name': 'Safe (Tijori)', 'mode': 'Safe', 'icon': Icons.lock_rounded},
  ];

  @override
  void initState() {
    super.initState();
    // Default regular payout to net salary due, advance defaults to empty or standard increment
    final defaultAmt = widget.staff.netSalaryDue > 0
        ? widget.staff.netSalaryDue
        : (widget.staff.monthlySalary > 0 ? widget.staff.monthlySalary : 0.0);
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

  void _onPayoutTypeChanged(String type) {
    setState(() {
      _payoutType = type;
      if (type == 'advance') {
        _amountController.text = '';
      } else {
        final netDue = widget.staff.netSalaryDue;
        _amountController.text = netDue > 0 ? netDue.toStringAsFixed(0) : '';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final notes = _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null;

    final selectedAcc = _paymentAccounts.firstWhere(
      (a) => a['name'] == _selectedPaymentMode,
      orElse: () => {'name': _selectedPaymentMode, 'mode': 'Cash'},
    );
    final paymentMode = selectedAcc['mode'] as String? ?? 'Cash';

    widget.onConfirm(
      staffId: widget.staff.id,
      amount: amount,
      paymentMode: paymentMode,
      payoutType: _payoutType,
      notes: notes,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final staff = widget.staff;
    final isAdv = _payoutType == 'advance';

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Segmented Payout Type Selector (Regular Salary vs Advance)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _onPayoutTypeChanged('regular_salary'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !isAdv
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : (isDark ? AppColors.bgDark : AppColors.bgLight),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !isAdv
                            ? AppColors.primary
                            : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                        width: !isAdv ? 1.5 : 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payments_rounded,
                          size: 16,
                          color: !isAdv ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Regular Salary',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: !isAdv ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _onPayoutTypeChanged('advance'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isAdv
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : (isDark ? AppColors.bgDark : AppColors.bgLight),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAdv
                            ? AppColors.warning
                            : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                        width: isAdv ? 1.5 : 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.handshake_rounded,
                          size: 16,
                          color: isAdv ? AppColors.warning : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Advance (অগ্রিম)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isAdv ? AppColors.warning : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Staff Balance Breakdown Summary Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgDark : AppColors.bgLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      staff.salaryType == SalaryType.daily ? 'Daily Wage Rate' : 'Monthly Salary',
                      style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 13),
                    ),
                    Text(
                      staff.salaryType == SalaryType.daily
                          ? '৳${staff.monthlySalary.toStringAsFixed(0)}/day'
                          : '৳${staff.monthlySalary.toStringAsFixed(0)}/mo',
                      style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                if (staff.totalAdvanceThisMonth > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Prior Advance Taken (অগ্রিম)',
                        style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '-৳${staff.totalAdvanceThisMonth.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      staff.owesCanteen ? 'Staff Owes Canteen' : 'Net Due to Settle',
                      style: TextStyle(
                        color: staff.owesCanteen ? AppColors.danger : AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      staff.owesCanteen
                          ? '৳${staff.owesCanteenAmount.toStringAsFixed(0)}'
                          : '৳${staff.netSalaryDue.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: staff.owesCanteen ? AppColors.danger : AppColors.success,
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

          // 3. Amount Field
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: isAdv ? 'Advance Amount (৳) *' : 'Salary Payout Amount (৳) *',
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
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter amount';
              final amt = double.tryParse(v.trim());
              if (amt == null || amt <= 0) return 'Please enter valid positive amount';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // 4. "Paid From" Canteen Wallet Channel
          Text(
            'Paid From (Canteen Wallet) *',
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _paymentAccounts.map((acc) {
              final isSelected = _selectedPaymentMode == acc['name'];
              return ChoiceChip(
                avatar: Icon(
                  acc['icon'] as IconData,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
                label: Text(
                  acc['name'] as String,
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                selected: isSelected,
                selectedColor: isAdv ? AppColors.warning : AppColors.primary,
                backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
                onSelected: (val) {
                  if (val) setState(() => _selectedPaymentMode = acc['name'] as String);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // 5. Notes / Reference
          TextFormField(
            controller: _notesController,
            style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Notes / Reason (e.g. Medicine advance, monthly closing)',
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
          const SizedBox(height: 24),

          // 6. Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdv ? AppColors.warning : AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    isAdv ? 'Confirm Advance Payout' : 'Confirm Salary Payout',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
