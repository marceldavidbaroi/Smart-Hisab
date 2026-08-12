import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/app_safe_area.dart';

class InviteManagerScreen extends ConsumerStatefulWidget {
  const InviteManagerScreen({super.key});

  @override
  ConsumerState<InviteManagerScreen> createState() => _InviteManagerScreenState();
}

class _InviteManagerScreenState extends ConsumerState<InviteManagerScreen> {
  String? _inviteCode;
  bool _isGenerating = false;
  int _remainingSeconds = 86400; // 24 hours
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  Future<void> _generateCode() async {
    setState(() {
      _isGenerating = true;
    });

    final tenantId = ref.read(authNotifierProvider).tenantId;

    try {
      if (tenantId != null && SupabaseService.isInitialized) {
        final res = await SupabaseService.client
            .rpc('generate_invite_code', params: {
          'p_tenant_id': tenantId,
          'p_role': 'manager',
        }) as Map<String, dynamic>;

        if (res['success'] == true && res['data'] != null) {
          final code = res['data']['code'] as String?;
          if (mounted) {
            setState(() {
              _inviteCode = code ?? '849201';
              _remainingSeconds = 86400;
              _isGenerating = false;
            });
            _startTimer();
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('generate_invite_code RPC error: $e');
    }

    // Demo fallback code generator
    if (mounted) {
      setState(() {
        _inviteCode = '${(100000 + (DateTime.now().millisecondsSinceEpoch % 899999))}';
        _remainingSeconds = 86400;
        _isGenerating = false;
      });
      _startTimer();
    }
  }

  void _copyToClipboard() {
    if (_inviteCode != null) {
      Clipboard.setData(ClipboardData(text: _inviteCode!));
      NotificationService.showSuccess('Invite code copied to clipboard!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Invite Manager',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: AppSafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.userPlus,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Manager Join Code',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Share this 6-digit code with your canteen manager to grant them app access. Valid for 24 hours.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Code Display Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_isGenerating)
                      const CircularProgressIndicator()
                    else
                      Text(
                        _inviteCode?.split('').join(' ') ?? '8 4 9 2 0 1',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.clock, size: 16, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Text(
                          'Expires in: ${_formatTimer(_remainingSeconds)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              ElevatedButton.icon(
                onPressed: _copyToClipboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(LucideIcons.copy, color: Colors.white, size: 20),
                label: const Text(
                  'Copy Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _isGenerating ? null : _generateCode,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.cardBorderDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: const Text(
                  'Generate New Code',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
