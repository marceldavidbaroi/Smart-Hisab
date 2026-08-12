import 'package:flutter/material.dart';
import 'login_screen.dart';

/// Landing Screen for Smart-Hisab.
/// Delegates to LoginScreen for unified Email & Password authentication.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
