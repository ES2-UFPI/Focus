import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/insights_mock.dart';
import 'package:frontend/models/insights_model.dart';
import 'package:frontend/screens/insights_screen.dart';
import 'package:frontend/services/insights_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _DelayedInsightsService extends InsightsService {
  const _DelayedInsightsService();

  @override
  Future<List<Insight>> fetchInsights() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return getInsightsMock();
  }

  @override
  Future<List<InsightJourneyEvent>> fetchJourney() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return getJornadaMock();
  }

  @override
  Future<InsightsDashboard> fetchDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return getInsightsDashboardMock();
  }
}

class _FailingInsightsService extends InsightsService {
  const _FailingInsightsService();

  @override
  Future<List<Insight>> fetchInsights() async {
    throw Exception('offline');
  }
}

void _configureLargeView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('shows loading, then the insight feed', (tester) async {
    _configureLargeView(tester);
    await tester.pumpWidget(
      const ShadApp(home: InsightsScreen(service: _DelayedInsightsService())),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const ValueKey('feed-row-desgaste')), findsOneWidget);
  });

  testWidgets('shows an error state with retry', (tester) async {
    _configureLargeView(tester);
    await tester.pumpWidget(
      const ShadApp(home: InsightsScreen(service: _FailingInsightsService())),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível carregar seus insights'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('insights-retry')), findsOneWidget);
  });

  testWidgets('renders the empty insights state', (tester) async {
    await tester.pumpWidget(const ShadApp(home: InsightsScreen(insights: [])));

    expect(
      find.text('Estude algumas sessões para desbloquear seus insights.'),
      findsOneWidget,
    );
  });

  testWidgets('renders the two insight sections with explanatory cards', (
    tester,
  ) async {
    _configureLargeView(tester);
    await tester.pumpWidget(
      ShadApp(home: InsightsScreen(insights: getInsightsMock())),
    );
    await tester.pump();

    expect(find.text('Pontos para melhorar'), findsOneWidget);
    expect(find.text('Descobertas'), findsOneWidget);
    expect(find.byKey(const ValueKey('feed-row-desgaste')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('feed-row-duracao_ideal')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('feed-row-melhor_horario')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('feed-row-amostra_insuficiente')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('feed-row-dimension-tempo')), findsNothing);
    expect(find.text('Padrão ruim observado'), findsWidgets);
    expect(find.text('Recomendação'), findsWidgets);
    expect(find.text('Resultado esperado'), findsWidgets);
    expect(find.text('Comportamento mapeado'), findsWidgets);
    expect(find.text('Como manter'), findsWidgets);
    expect(find.text('Próximo uso'), findsWidgets);
    expect(find.text('Ação recomendada'), findsOneWidget);
    expect(find.text('Informativo'), findsWidgets);
    expect(find.text('Descoberta'), findsNothing);
    expect(find.text('Recomendação'), findsWidgets);
    expect(find.text('Sono e rotina'), findsOneWidget);
    expect(find.text('Saúde'), findsNothing);
    expect(find.byKey(const ValueKey('feed-ack-desgaste')), findsOneWidget);
    expect(find.text('Taxa'), findsNothing);
    expect(find.text('60%'), findsNothing);
    expect(find.text('Recomendação de melhoria'), findsNothing);
  });

  testWidgets('subject filter narrows the insight feed', (tester) async {
    _configureLargeView(tester);
    await tester.pumpWidget(
      ShadApp(home: InsightsScreen(insights: getInsightsMock())),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('subject-filter-Banco de Dados')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('feed-row-duracao_ideal')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('feed-row-desgaste')), findsNothing);
    expect(find.byKey(const ValueKey('feed-row-melhor_horario')), findsNothing);
  });

  testWidgets('keeps only improvement cards in the evolution tab', (
    tester,
  ) async {
    _configureLargeView(tester);
    await tester.pumpWidget(
      ShadApp(home: InsightsScreen(insights: getInsightsMock())),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('view-evolucao')));
    await tester.pump();

    expect(find.text('Histórico das mudanças'), findsOneWidget);
    expect(find.text('Antes × agora'), findsNothing);
    expect(find.text('Da hipótese ao resultado'), findsNothing);
    expect(find.text('A história de cada disciplina'), findsNothing);
    expect(
      find.byKey(const ValueKey('evolution-improvement-desgaste')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('evolution-improvement-duracao_ideal')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('evolution-improvement-taxa_furo')),
      findsOneWidget,
    );
    expect(
      find.text('Menos estudo tarde'),
      findsOneWidget,
    );
    expect(find.text('Blocos mais curtos'), findsOneWidget);
    expect(find.text('Sexta à noite evitada'), findsOneWidget);
    expect(
      find.textContaining('Relacionado: Cansaço no fim do dia'),
      findsOneWidget,
    );
    expect(find.text('Fonte'), findsOneWidget);
    expect(find.text('Sono e rotina'), findsOneWidget);
    expect(find.text('Saúde'), findsNothing);
    expect(
      find.text('Produtividade'),
      findsOneWidget,
    );
    expect(find.text('3,5'), findsOneWidget);
    expect(find.text('4,2'), findsOneWidget);
    expect(find.text('+20%'), findsOneWidget);
    expect(find.text('+43%'), findsOneWidget);
    expect(find.text('-20%'), findsOneWidget);
    expect(find.textContaining('Hábito corrigido'), findsNothing);
    expect(find.textContaining('Ajuste:'), findsNothing);
    expect(find.textContaining('Problema:'), findsNothing);
    expect(find.textContaining('p.p.'), findsNothing);
    expect(
      find.textContaining('Relacionado:'),
      findsWidgets,
    );
    final latestTop = tester.getTopLeft(
      find.byKey(const ValueKey('evolution-improvement-taxa_furo')),
    );
    final middleTop = tester.getTopLeft(
      find.byKey(const ValueKey('evolution-improvement-duracao_ideal')),
    );
    final oldestTop = tester.getTopLeft(
      find.byKey(const ValueKey('evolution-improvement-desgaste')),
    );
    expect(latestTop.dy, lessThan(middleTop.dy));
    expect(middleTop.dy, lessThan(oldestTop.dy));
    expect(find.textContaining('Você rendia menos'), findsNothing);
    expect(find.textContaining('Você passou a reservar'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('evolution-improvement-desgaste')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detalhe do insight'), findsOneWidget);
    expect(
      find.text('O cansaço aparece quando você empilha estudo no fim do dia'),
      findsOneWidget,
    );
  });

  testWidgets('lays out the calm hierarchy on a phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ShadApp(home: InsightsScreen(insights: getInsightsMock())),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('feed-row-desgaste')),
      findsOneWidget,
    );
  });
}
