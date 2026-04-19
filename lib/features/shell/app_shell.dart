import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, required this.location, super.key});
  final Widget child;
  final String location;

  static const _tabs = [
    ('Scan', Icons.camera_alt, '/scan'),
    ('Collection', Icons.style, '/collection'),
    ('Settings', Icons.settings, '/settings'),
  ];

  int get _index {
    final i = _tabs.indexWhere((t) => location.startsWith(t.$3));
    return i < 0 ? 1 : i; // unknown location → Collection
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => context.go(_tabs[i].$3),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(icon: Icon(t.$2), label: t.$1),
        ],
      ),
    );
  }
}

