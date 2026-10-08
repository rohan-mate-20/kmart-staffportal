import 'package:flutter/material.dart';

import '../models/models.dart';
import 'delivery_dashboard_screen.dart';
import 'delivery_history_screen.dart';
import 'packer_dashboard_screen.dart';
import 'packer_history_screen.dart';
import 'profile_screen.dart';

/// Holds the bottom navigation bar and swaps the body per role.
class HomeShell extends StatefulWidget {
  final StaffUser user;
  final int initialIndex;

  const HomeShell({super.key, required this.user, this.initialIndex = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;

  bool get _isPacker => widget.user.role == StaffRole.packer;

  List<Widget> get _pages => _isPacker
      ? [
          PackerDashboardScreen(user: widget.user),
          PackerHistoryScreen(user: widget.user),
          ProfileScreen(user: widget.user),
        ]
      : [
          DeliveryDashboardScreen(user: widget.user),
          DeliveryHistoryScreen(user: widget.user),
          ProfileScreen(user: widget.user),
        ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE6E8EF))),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (value) => setState(() => _index = value),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: _isPacker ? 'Orders' : 'Deliveries',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.access_time),
              activeIcon: Icon(Icons.watch_later),
              label: 'History',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
