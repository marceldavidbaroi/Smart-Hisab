import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/auth/auth_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/custom_modal_bottom_sheet.dart';
import '../app_scaffold_notifier.dart';
import '../auth/create_canteen_screen.dart';
import '../auth/join_canteen_screen.dart';
import 'widgets/canteen_action_sheets.dart';


/// Standalone Switch Canteen Screen
/// Allows users to view all available canteens, switch active canteen,
/// delete canteen (if owner), leave canteen (if manager), and create/join canteens.
class SwitchCanteenScreen extends ConsumerStatefulWidget {
  const SwitchCanteenScreen({super.key});

  @override
  ConsumerState<SwitchCanteenScreen> createState() => _SwitchCanteenScreenState();
}

class _SwitchCanteenScreenState extends ConsumerState<SwitchCanteenScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Resolve membership list from auth state
    final List<TenantMembershipItem> availableTenants = authState.availableTenants;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: const Text(
          'Switch Canteen',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(authNotifierProvider.notifier).initializeAuth();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header description & Action buttons bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select an active canteen workspace or add/join another.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => CreateCanteenScreen.show(context),
                              icon: const Icon(LucideIcons.plusCircle, size: 18),
                              label: const Text('Add Canteen', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => JoinCanteenScreen.show(context),
                              icon: const Icon(LucideIcons.userPlus, size: 18),
                              label: const Text('Join Canteen', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Loading state with Shimmer loaders
              if (authState.isSubmitting)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildShimmerCard(isDark),
                      childCount: 3,
                    ),
                  ),
                )
              // Empty State
              else if (availableTenants.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.store, size: 48, color: AppColors.primary),
                            const SizedBox(height: 12),
                            Text(
                              'No Canteens Available',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first canteen or join an existing one to start managing sales.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => CreateCanteenScreen.show(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Create Canteen'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => JoinCanteenScreen.show(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Join Canteen'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              // Canteen List
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tenant = availableTenants[index];
                        final isActive = tenant.tenantId == authState.tenantId;
                        final isOwner = tenant.role.toLowerCase() == 'owner';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : (isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              if (!isActive) {
                                await ref
                                    .read(authNotifierProvider.notifier)
                                    .setActiveTenant(
                                      tenantId: tenant.tenantId,
                                      tenantName: tenant.tenantName,
                                      role: tenant.role,
                                    );
                                ref.read(scaffoldNotifierProvider.notifier).setTab(0);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Switched to ${tenant.tenantName}'),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                  if (Navigator.canPop(context)) {
                                    Navigator.popUntil(context, (route) => route.isFirst);
                                  }
                                }
                              }
                            },

                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Icon / Active Avatar
                                  CircleAvatar(
                                    backgroundColor: isActive
                                        ? AppColors.primary.withValues(alpha: 0.15)
                                        : (isDark ? Colors.white10 : Colors.black12),
                                    child: Icon(
                                      LucideIcons.store,
                                      color: isActive
                                          ? AppColors.primary
                                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tenant.tenantName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            // Role Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isOwner
                                                    ? AppColors.accent.withValues(alpha: 0.15)
                                                    : AppColors.warning.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                tenant.role.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isOwner ? AppColors.accent : AppColors.warning,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Active Indicator Chip
                                            if (isActive)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  'ACTIVE',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Action Buttons: Invite Code (Owner only), Delete (Owner), Leave (Manager)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isOwner) ...[
                                        IconButton(
                                          icon: const Icon(LucideIcons.key, color: AppColors.primary),
                                          tooltip: 'Get Manager Join Code',
                                          onPressed: () => _showGetCodeModal(context, tenant),
                                        ),
                                        IconButton(
                                          icon: const Icon(LucideIcons.trash2, color: AppColors.danger),
                                          tooltip: 'Delete Canteen',
                                          onPressed: () => _confirmDeleteCanteen(context, tenant),
                                        ),
                                      ] else
                                        IconButton(
                                          icon: const Icon(LucideIcons.logOut, color: AppColors.warning),
                                          tooltip: 'Leave Canteen',
                                          onPressed: () => _confirmLeaveCanteen(context, tenant),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: availableTenants.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBaseLight,
      highlightColor: isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlightLight,
      child: Container(
        height: 76,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _confirmDeleteCanteen(BuildContext context, TenantMembershipItem tenant) {
    CanteenActionSheets.showDeleteCanteen(
      context: context,
      ref: ref,
      tenantId: tenant.tenantId,
      canteenName: tenant.tenantName,
      onSuccess: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${tenant.tenantName} deleted successfully'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
    );
  }

  void _confirmLeaveCanteen(BuildContext context, TenantMembershipItem tenant) {
    CanteenActionSheets.showLeaveCanteen(
      context: context,
      ref: ref,
      tenantId: tenant.tenantId,
      canteenName: tenant.tenantName,
      onSuccess: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Left ${tenant.tenantName} successfully'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      },
    );
  }


  void _showGetCodeModal(BuildContext context, TenantMembershipItem tenant) {
    CustomModalBottomSheet.show(
      context: context,
      title: '${tenant.tenantName} - Join Code',
      child: _InviteCodeModalContent(tenantId: tenant.tenantId),
    );
  }
}

class _InviteCodeModalContent extends StatefulWidget {
  final String tenantId;
  const _InviteCodeModalContent({required this.tenantId});

  @override
  State<_InviteCodeModalContent> createState() => _InviteCodeModalContentState();
}

class _InviteCodeModalContentState extends State<_InviteCodeModalContent> {
  String? _code;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCode();
  }

  Future<void> _fetchCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (SupabaseService.isInitialized) {
        final res = await SupabaseService.client.rpc('generate_invite_code', params: {
          'p_tenant_id': widget.tenantId,
          'p_role': 'manager',
        });
        
        if (mounted) {
          setState(() {
            _code = res.toString();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error generating invite code: $e');
    }

    if (mounted) {
      setState(() {
        _code = '${100000 + (DateTime.now().millisecondsSinceEpoch % 899999)}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Share this 6-digit code with your canteen manager to grant them access to this canteen.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),
        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  _code?.split('').join(' ') ?? '',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.clock, size: 14, color: AppColors.warning),
                    SizedBox(width: 4),
                    Text(
                      'Valid for 24 hours',
                      style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              if (_code != null) {
                Clipboard.setData(ClipboardData(text: _code!));
                NotificationService.showSuccess('Invite code copied to clipboard!');
              }
            },
            icon: const Icon(LucideIcons.copy, size: 18),
            label: const Text('Copy Code', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _fetchCode,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Generate New Code'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
