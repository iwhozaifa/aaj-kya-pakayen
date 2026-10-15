import 'package:flutter/material.dart';

/// A value with large − and + buttons, kept within [min] and [max].
class NumberStepper extends StatelessWidget {
  const new({
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.decreaseTooltip,
    required this.increaseTooltip,
    required this.onChanged,
    super.key,
  });

  final int value;
  final int min;
  final int max;

  /// The value as shown, e.g. "4 people".
  final String label;
  final String decreaseTooltip;
  final String increaseTooltip;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const buttonSize = Size.square(56);
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: decreaseTooltip,
          style: IconButton.styleFrom(minimumSize: buttonSize),
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove, size: 28),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        IconButton.filled(
          tooltip: increaseTooltip,
          style: IconButton.styleFrom(minimumSize: buttonSize),
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add, size: 28),
        ),
      ],
    );
  }
}
