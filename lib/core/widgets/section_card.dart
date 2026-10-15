import 'package:flutter/material.dart';

/// Rounded card with an optional heading, used to group content.
class SectionCard extends StatelessWidget {
  const new({required this.child, this.title, super.key});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title case final title?) ...[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
