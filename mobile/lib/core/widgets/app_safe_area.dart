import 'package:flutter/material.dart';

/// Reusable safe area wrapper complying with AGENTS.md Constraint #5:
/// Always wrap views with SafeArea widget.
class AppSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;

  const AppSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      child: child,
    );
  }
}
