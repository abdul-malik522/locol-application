import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/theme/app_colors.dart';
import 'package:localtrade/features/messages/providers/messages_provider.dart';

class BottomNavShell extends ConsumerStatefulWidget {
  const BottomNavShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends ConsumerState<BottomNavShell> {
  static const _items = [
    _NavItem(Icons.home_filled, 'Home'),
    _NavItem(Icons.search_rounded, 'Search'),
    _NavItem(Icons.add_circle_outlined, 'Create'),
    _NavItem(Icons.chat_bubble_outline_rounded, 'Messages'),
    _NavItem(Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        height: 72,
        backgroundColor: Theme.of(context).colorScheme.surface,
        destinations: List.generate(_items.length, (index) {
          final item = _items[index];
          final icon = NavigationDestination(
            icon: _buildIcon(item, index, unreadCount),
            label: item.label,
          );
          return icon;
        }),
        onDestinationSelected: (index) {
          HapticFeedback.lightImpact();
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
      ),
    );
  }

  Widget _buildIcon(_NavItem item, int index, int unreadCount) {
    final isSelected = index == widget.navigationShell.currentIndex;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;
    final icon = Icon(item.icon, color: color);

    if (index == 3 && unreadCount > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          Positioned(
            right: -6,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return icon;
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

