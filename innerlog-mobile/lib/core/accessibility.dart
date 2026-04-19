import 'package:flutter/material.dart';

/// Accessibility helpers for InnerLog.
/// Ensures minimum touch targets and proper semantic labels.

/// Wraps a widget to ensure minimum 44x44 touch target (WCAG 2.5.5).
class AccessibleTap extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;

  const AccessibleTap({
    super.key,
    required this.child,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Mood emoji with semantic label for screen readers.
class MoodEmoji extends StatelessWidget {
  final int score;
  final bool selected;
  final VoidCallback? onTap;
  final double selectedSize;
  final double normalSize;

  static const _emojis = ['', '😢', '😟', '😐', '🙂', '😄'];
  static const _labels = ['', 'Rất buồn', 'Buồn', 'Bình thường', 'Vui', 'Rất vui'];

  const MoodEmoji({
    super.key,
    required this.score,
    this.selected = false,
    this.onTap,
    this.selectedSize = 40,
    this.normalSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mood ${_labels[score]}, điểm $score trên 5',
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Center(
            child: Text(
              _emojis[score],
              style: TextStyle(fontSize: selected ? selectedSize : normalSize),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton loading placeholder.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton card for loading states (replaces bare CircularProgressIndicator).
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(height: 16, width: 120),
            const SizedBox(height: 12),
            const SkeletonBox(height: 12),
            const SizedBox(height: 8),
            const SkeletonBox(height: 12, width: 200),
            const SizedBox(height: 8),
            const SkeletonBox(height: 12, width: 160),
          ],
        ),
      ),
    );
  }
}
