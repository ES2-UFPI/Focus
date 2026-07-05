import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_shell_provider.dart';
import 'app_sidebar.dart';

class AppScaffold extends StatelessWidget {
  static const double desktopBreakpoint = 900;

  final List<Widget> screens;

  const AppScaffold({
    super.key,
    required this.screens,
  });

  @override
  Widget build(BuildContext context) {
    final useSidebar = MediaQuery.sizeOf(context).width >= desktopBreakpoint;

    return Consumer<AppShellProvider>(
      builder: (context, shell, _) {
        return Scaffold(
          body: Row(
            children: [
              if (useSidebar)
                AppSidebar(
                  currentPage: shell.currentPage,
                  onPageChanged: shell.selectPage,
                ),
              Expanded(
                child: IndexedStack(
                  index: shell.currentIndex,
                  children: screens,
                ),
              ),
            ],
          ),
          bottomNavigationBar: useSidebar
              ? null
              : _BottomNavigationBar(
                  currentIndex: shell.currentIndex,
                  onDestinationSelected: shell.selectIndex,
                ),
        );
      },
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const _BottomNavigationBar({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      elevation: 3,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: 'Atividades',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Eventos',
        ),

         NavigationDestination(
          icon: Icon(Icons.flag_outlined),
          selectedIcon: Icon(Icons.flag_rounded),
          label: 'Metas',
        ),
        NavigationDestination(
          icon: Icon(Icons.track_changes_outlined),
          selectedIcon: Icon(Icons.track_changes_rounded),
          label: 'Consistência',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_suggest_rounded),
          label: 'Ajustes',
        ),
      ],
    );
  }
}
