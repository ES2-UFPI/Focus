import 'package:flutter/material.dart';

import 'agenda_screen.dart';
import 'materiais_screen.dart';
import 'consistencia_screen.dart';
import 'ciclo_estudos_screen.dart';
import 'configuracoes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const AgendaScreen(),
      const MateriaisScreen(),
      const ConsistenciaScreen(),
      const CicloEstudosScreen(),
      const ConfiguracoesScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        elevation: 3,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_open_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Materiais',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes_rounded),
            label: 'Consistência',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_week_outlined),
            selectedIcon: Icon(Icons.view_week_rounded),
            label: 'Ciclos',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_suggest_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
