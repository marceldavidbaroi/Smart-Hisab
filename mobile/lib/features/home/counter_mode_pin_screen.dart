import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/staff_member.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import '../app_scaffold_notifier.dart';

class CounterModePinScreen extends ConsumerStatefulWidget {
  const CounterModePinScreen({super.key});

  static Future<void> show(BuildContext context) {
    return CustomModalBottomSheet.show(
      context: context,
      title: 'Counter Mode Staff Lock',
      child: const CounterModePinScreen(),
    );
  }

  @override
  ConsumerState<CounterModePinScreen> createState() => _CounterModePinScreenState();
}

class _CounterModePinScreenState extends ConsumerState<CounterModePinScreen> {
  final List<StaffMember> _staffList = const [
    StaffMember(id: 'st-1', name: 'Karim (Manager)', role: StaffRole.manager, pinCode: '1234'),
    StaffMember(id: 'st-2', name: 'Rahim (Cashier)', role: StaffRole.staff, pinCode: '5678'),
    StaffMember(id: 'st-3', name: 'Sumon (Counter)', role: StaffRole.staff, pinCode: '0000'),
  ];

  StaffMember? _selectedStaff;
  String _enteredPin = '';
  String? _errorText;

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorText = null;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorText = null;
      });
    }
  }

  void _verifyPin() {
    if (_selectedStaff == null) return;
    
    // Validate PIN (accept matching PIN or default demo '1234')
    final expectedPin = _selectedStaff!.pinCode ?? '1234';
    if (_enteredPin == expectedPin || _enteredPin == '1234') {
      ref.read(scaffoldNotifierProvider.notifier).activateCounterMode(_selectedStaff!);
      Navigator.of(context).pop();
    } else {
      setState(() {
        _errorText = 'Incorrect PIN code. Try again.';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_selectedStaff == null) ...[
            Text(
              'Select Active Staff Member',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _staffList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final staff = _staffList[index];
                return ListTile(
                  tileColor: AppColors.bgDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      staff.name[0],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    staff.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // AGENTS.md rule 7
                    ),
                  ),
                  subtitle: Text(
                    'Role: ${staff.role.name.toUpperCase()}',
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(LucideIcons.chevronRight, color: AppColors.textSecondaryDark),
                  onTap: () => setState(() => _selectedStaff = staff),
                );
              },
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    _selectedStaff!.name[0],
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedStaff!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Enter 4-Digit PIN (Demo: 1234)',
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedStaff = null;
                    _enteredPin = '';
                    _errorText = null;
                  }),
                  child: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? AppColors.primary : AppColors.textSecondaryDark,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // Keypad Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map(
                  (digit) => _buildKeypadButton(digit, () => _onDigitPressed(digit)),
                ),
                const SizedBox(),
                _buildKeypadButton('0', () => _onDigitPressed('0')),
                _buildKeypadButton('⌫', _onDeletePressed),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorderDark),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
