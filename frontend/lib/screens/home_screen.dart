import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';
import 'agenda_screen.dart';
import 'atividades_screen.dart';
import 'consistencia_screen.dart';
import 'configuracoes_screen.dart';
import 'insights_screen.dart';
import 'meta_semanais_screen.dart';
import 'notas_screen.dart';
import 'pomodoro_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      screens: [
        AtividadesScreen(),
        AgendaScreen(),
        MetasSemanaisScreen(),
        ConsistenciaScreen(),
        InsightsScreen(),
        PomodoroScreen(),
        NotasScreen(),
        ConfiguracoesScreen(),
      ],
    );
  }
}