import 'package:flutter/material.dart';

/// Temporary home screen until `feature/today-screen` lands.
///
/// Intentionally text-free: user-facing strings arrive with the ARB files in
/// `feature/design-system`.
class TodayPlaceholderScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Icon(Icons.soup_kitchen, size: 96)),
    );
  }
}
