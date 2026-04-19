import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

class ShellScreen extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final void Function(int) onDestinationSelected;

  const ShellScreen({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined, semanticLabel: 'Home'), selectedIcon: const Icon(Icons.home), label: l.home),
          NavigationDestination(icon: const Icon(Icons.mood_outlined, semanticLabel: 'Check-in'), selectedIcon: const Icon(Icons.mood), label: l.checkin),
          NavigationDestination(icon: const Icon(Icons.insights_outlined, semanticLabel: 'Insights'), selectedIcon: const Icon(Icons.insights), label: l.insights),
          NavigationDestination(icon: const Icon(Icons.flag_outlined, semanticLabel: 'Goals'), selectedIcon: const Icon(Icons.flag), label: l.goals),
          NavigationDestination(icon: const Icon(Icons.person_outline, semanticLabel: 'Profile'), selectedIcon: const Icon(Icons.person), label: l.profile),
        ],
      ),
    );
  }
}
