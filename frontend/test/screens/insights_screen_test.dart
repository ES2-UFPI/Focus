import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/data/insights_mock.dart';
import 'package:frontend/models/insights_model.dart';
import 'package:frontend/screens/insights_screen.dart';
import 'package:frontend/services/insights_service.dart';
import 'package:frontend/widgets/insights/insight_kpi_strip.dart';
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
  testWidgets('shows loading, then the editorial experience', (tester) async {
    _configureLargeView(tester);
    await tester.pumpWidget(
      const ShadApp(home: InsightsScreen(service: _DelayedInsightsService())),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.byKey(const ValueKey('insight-editorial-summary')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('insight-kpi-strip')), findsOneWidget);
    expect(find.byKey(const ValueKey('calm-toggle')), findsNothing);
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

  testWidgets('groups eligible insights and dimensions by priority', (
    tester,
  ) async {
    _configureLargeView(tester);
    await tester.pumpWidget(
      ShadApp(home: InsightsScreen(insights: getInsightsMock())),
    );
    await tester.pump();

    expect(find.text('⚠️ Vale sua atenção'), findsOneWidget);
    expect(find.text('💡 Descobertas'), findsOneWidget);
    expect(find.text('📈 Evolução'), findsOneWidget);
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
    expect(
      find.byKey(const ValueKey('insufficient-patterns-note')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('feed-row-dimension-tempo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('feed-row-dimension-recuperacao')),
      findsOneWidget,
    );
  });

  testWidgets('editorial CTA opens the anchored insight detail', (
    tester,
  ) async {
    _configureLargeView(tester);
    await tester.pumpWidget(
      ShadApp(home: InsightsScreen(insights: getInsightsMock())),
    );
    await tester.pump();

    final summary = tester.widget<Text>(
      find.byKey(const ValueKey('insight-editorial-summary')),
    );
    final rootSpan = summary.textSpan! as TextSpan;
    final ctaSpan = rootSpan.children!.last as TextSpan;
    (ctaSpan.recognizer! as TapGestureRecognizer).onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Detalhe do insight'), findsOneWidget);
    expect(
      find.text('Seus registros recentes mostram sinais de cansaço'),
      findsOneWidget,
    );
  });

  testWidgets('shows three KPIs with semantic variation colors', (
    tester,
  ) async {
    _configureLargeView(tester);
    await tester.pumpWidget(
      ShadApp(home: InsightsScreen(insights: getInsightsMock())),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('kpi-produtividade-es2')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('kpi-cancelamentos-sexta')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('kpi-tarefas-no-prazo')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('kpi-produtividade-es2')),
        matching: find.text('4/5'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('kpi-cancelamentos-sexta')),
        matching: find.text('10%'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('kpi-tarefas-no-prazo')),
        matching: find.text('78%'),
      ),
      findsOneWidget,
    );

    final variation = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('kpi-variation-cancelamentos-sexta')),
    );
    final decoration = variation.decoration as BoxDecoration;
    expect(decoration.color, AppColors.success.withValues(alpha: 0.1));
    expect(
      comparisonVariationIsPositive(getInsightsDashboardMock().comparacoes[1]),
      isTrue,
    );
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

  testWidgets('keeps the evolution journey in its own tab', (tester) async {
    _configureLargeView(tester);
    await tester.pumpWidget(
      ShadApp(home: InsightsScreen(insights: getInsightsMock())),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('view-evolucao')));
    await tester.pump();

    expect(find.text('Antes × agora'), findsOneWidget);
    expect(find.text('Da hipótese ao resultado'), findsOneWidget);
    expect(find.text('A história de cada disciplina'), findsOneWidget);
    expect(find.text('Histórico das mudanças'), findsOneWidget);
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
      find.byKey(const ValueKey('insight-editorial-summary')),
      findsOneWidget,
    );
  });
}
