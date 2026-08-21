import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/time_phase_helper.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../open_day_bottom_sheet.dart';
import 'animated_celestial_hero.dart';

/// Dynamic, time-aware hero card displayed on the Home Dashboard when the business day is closed.
/// Automatically adapts its sky gradient, moving celestial animations (Sun/Moon/Stars),
/// and canteen shift prompts based on the current real-time.
class DynamicStartDayCard extends StatefulWidget {
  final DateTime? overrideTime;

  const DynamicStartDayCard({
    super.key,
    this.overrideTime,
  });

  @override
  State<DynamicStartDayCard> createState() => _DynamicStartDayCardState();
}

class _DynamicStartDayCardState extends State<DynamicStartDayCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final phase = TimePhaseHelper.getPhase(widget.overrideTime);
    final primaryAccent = TimePhaseHelper.getPrimaryAccent(phase);
    final gradientColors = TimePhaseHelper.getCardGradient(phase, isDark);
    final badgeLabel = TimePhaseHelper.getBadgeLabel(phase);
    final greeting = TimePhaseHelper.getGreeting(phase);
    final subtitle = TimePhaseHelper.getSubtitle(phase);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryAccent.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryAccent.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle ambient starlight or sunbeam glow
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryAccent.withValues(alpha: isDark ? 0.12 : 0.08),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Tag: Live Shift & Phase Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryAccent.withValues(alpha: isDark ? 0.4 : 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryAccent.withValues(alpha: 0.8),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            badgeLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12, // AGENTS.md rule 7
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Center Animated 60fps Celestial Hero (Sun with Rotating Rays or Moon with Stars)
                AnimatedCelestialHero(
                  phase: phase,
                  size: 92,
                ),
                const SizedBox(height: 14),

                // Dynamic Greeting Title
                Text(
                  greeting,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18, // AGENTS.md rule 7
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                // Contextual Guidance Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 14,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // Glowing Interactive "Start Business Day" Action Button
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: _glowAnimation.value),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => OpenDayBottomSheet.show(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(LucideIcons.playCircle, size: 22),
                      label: Text(
                        l10n?.homeStartDayButton ?? 'Start Business Day',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16, // AGENTS.md rule 7
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
