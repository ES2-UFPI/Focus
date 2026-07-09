import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_shell_provider.dart';
import 'app_sidebar.dart';

class AppScaffold extends StatelessWidget {
  static const double desktopBreakpoint = 900;

  final List<Widget> screens;

  const AppScaffold({super.key, required this.screens});

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

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

/// Barra de navegação inferior própria. São 9 destinos — mais do que a
/// `NavigationBar` do Material comporta com rótulo em telas estreitas
/// (320–425px), onde ela quebra o texto no meio da palavra. Aqui cada rótulo
/// fica dentro de um [FittedBox] que reduz a fonte só o necessário para caber
/// sempre em uma única linha, em qualquer largura.
class _BottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const _BottomNavigationBar({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  static const List<_NavItem> _items = [
    _NavItem(Icons.assignment_outlined, Icons.assignment_rounded, 'Tarefas'),
    _NavItem(Icons.calendar_today_outlined, Icons.calendar_month_rounded, 'Eventos'),
    _NavItem(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Matérias'),
    _NavItem(Icons.flag_outlined, Icons.flag_rounded, 'Metas'),
    _NavItem(Icons.track_changes_outlined, Icons.track_changes_rounded, 'Ritmo'),
    _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome_rounded, 'Insights'),
    _NavItem(Icons.timer_outlined, Icons.timer_rounded, 'Pomodoro'),
    _NavItem(Icons.description_outlined, Icons.description_rounded, 'Notas'),
    _NavItem(Icons.settings_outlined, Icons.settings_suggest_rounded, 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(child: _buildItem(context, i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _items[index];
    final selected = index == currentIndex;
    final color = selected ? AppColors.brandPrimary : AppColors.textMuted;

    return InkWell(
      onTap: () => onDestinationSelected(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.brandPrimary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(selected ? item.selectedIcon : item.icon,
                  color: color, size: 22),
            ),
            const SizedBox(height: 3),
            // FittedBox garante o rótulo em 1 linha: reduz a fonte apenas o
            // necessário para caber na largura da célula (útil em 320px).
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 12,
                  height: 1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
