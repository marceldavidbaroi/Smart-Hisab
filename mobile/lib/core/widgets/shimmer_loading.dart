import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';

/// Standard Skeleton / Shimmer loaders complying with AGENTS.md Constraint #2:
/// Always use Skeleton / Shimmer loaders for loading states instead of generic progress indicators.
class ShimmerCardLoader extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const ShimmerCardLoader({
    super.key,
    this.height = 100,
    this.width = double.infinity,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBaseLight;
    final highlightColor = isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlightLight;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer list placeholder for item cards
class ShimmerListLoader extends StatelessWidget {
  final int itemCount;

  const ShimmerListLoader({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const ShimmerCardLoader(height: 72),
    );
  }
}
