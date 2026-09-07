import 'package:flutter/material.dart';

class AdaptiveFieldAction extends StatelessWidget {
  const AdaptiveFieldAction({
    required this.field,
    required this.action,
    super.key,
  });

  final Widget field;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final usesLargeText = MediaQuery.textScalerOf(context).scale(16) > 22;
        if (constraints.maxWidth < 340 || usesLargeText) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [field, const SizedBox(height: 12), action],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field),
            const SizedBox(width: 12),
            action,
          ],
        );
      },
    );
  }
}
