import 'package:flutter/material.dart';

import '../pages/biblioteca_materiais_page.dart';
import '../widgets/app_scaffold.dart';
import 'agenda_screen.dart';
import 'atividades_screen.dart';
import 'consistencia_screen.dart';
import 'ciclo_estudos_screen.dart';
import 'configuracoes_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      screens: [
        AgendaScreen(),
        AtividadesScreen(),
        BibliotecaMateriaisPage(),
        ConsistenciaScreen(),
        CicloEstudosScreen(),
        ConfiguracoesScreen(),
      ],
    );
  }
}
