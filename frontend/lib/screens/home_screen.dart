import 'package:flutter/material.dart';

import '../widgets/app_scaffold.dart';
import 'agenda_screen.dart';
import 'atividades_screen.dart';
import 'consistencia_screen.dart';
import 'configuracoes_screen.dart';
import 'meta_semanais_screen.dart';

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
        ConfiguracoesScreen(),
      ],
    );
  }
}