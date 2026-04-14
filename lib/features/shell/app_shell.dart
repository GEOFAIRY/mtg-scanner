import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, required this.location, super.key});
  final Widget child;
  final String location;

  static const _tabs = [
    ('Scan', Icons.camera_alt, '/scan'),
    ('Queue', Icons.inbox, '/queue'),
    ('Collection', Icons.style, '/collection'),
    ('Export', Icons.ios_share, '/export'),
    ('Settings', Icons.settings, '/settings'),
  ];

  int get _index =>
      _tabs.indexWhere((t) => location.startsWith(t.$3)).clamp(0, 4);

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
