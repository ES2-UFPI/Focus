import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/data/insights_mock.dart';
import 'package:frontend/models/insights_model.dart';
import 'package:frontend/screens/insights_screen.dart';
import 'package:frontend/services/insights_service.dart';
import 'package:frontend/widgets/insight_card.dart';
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
}

class _FailingInsightsService extends InsightsService {
  const _FailingInsightsService();

  @override
  Future<List<Insight>> fetchInsights() async {
    throw Exception('offline');
  }
}

Widget _expandedInsightsApp() {
  return const ShadApp(home: InsightsScreen(initiallyShowPatternLibrary: true));
}

Future<void> _scrollToPatternLibrary(WidgetTester tester) async {
  final outerScroll = find
      .descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      )
      .first;
  final categories = find.text('Todos');
  await tester.scrollUntilVisible(categories, 500, scrollable: outerScroll);
  await tester.ensureVisible(categories);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a loading indicator before insights resolve', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ShadApp(home: InsightsScreen(service: _DelayedInsightsService())),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Três decisões, sem sobrecarga'), findsOneWidget);
  });

  testWidgets('shows an error state with retry when loading fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
  testWidgets('calm mode compresses the top into a single summary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShadApp(home: InsightsScreen()));
    await tester.pumpAndSettle();

    // Padrão: modo detalhado, com os blocos densos do topo.
    expect(find.text('Três decisões, sem sobrecarga'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calm-toggle')));
    await tester.pumpAndSettle();

    // Modo calmo: um resumo único, sem os blocos densos.
    expect(find.text('Sua semana em foco'), findsOneWidget);
    expect(find.text('Três decisões, sem sobrecarga'), findsNothing);
    expect(find.text('Saúde do seu estudo'), findsNothing);
  });

  testWidgets('renders mocked insights and category filters', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_expandedInsightsApp());
    await tester.pumpAndSettle();

    expect(find.text('Insights'), findsNWidgets(2));
    expect(find.text('Três decisões, sem sobrecarga'), findsOneWidget);
    expect(find.text('Saúde do seu estudo'), findsOneWidget);
    expect(find.text('Evolução'), findsOneWidget);
    expect(find.byType(InsightCard), findsNothing);

    await _scrollToPatternLibrary(tester);

    expect(find.text('Biblioteca de padrões'), findsOneWidget);
    expect(find.text('Resumo dos seus padrões'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Todas as matérias'), findsOneWidget);
    expect(find.text('Tempo'), findsOneWidget);
    expect(find.text('Saúde'), findsOneWidget);
    expect(find.text('Método'), findsOneWidget);
    expect(find.text('Fontes de dados'), findsNothing);
    expect(find.text('Mostrar insights ocultos'), findsNothing);
    expect(find.text('Confiança alta'), findsWidgets);
    expect(find.text('Confiança média'), findsWidgets);
    expect(find.textContaining('60% das sessões'), findsWidgets);
    expect(
      find.textContaining('Dados insuficientes — continue registrando'),
      findsOneWidget,
    );
    expect(find.text('+41%'), findsOneWidget);
  });

  testWidgets('renders the empty insights state', (tester) async {
    await tester.pumpWidget(const ShadApp(home: InsightsScreen(insights: [])));

    expect(
      find.text('Estude algumas sessões para desbloquear seus insights.'),
      findsOneWidget,
    );
  });

  testWidgets('hides weekly plan when there is no eligible insight', (
    tester,
  ) async {
    final insufficient = getInsightsMock().where(
      (insight) => insight.confianca == 'insuficiente',
    );

    await tester.pumpWidget(
      ShadApp(home: InsightsScreen(insights: insufficient.toList())),
    );

    expect(find.text('Três decisões, sem sobrecarga'), findsNothing);
  });

  testWidgets('filters insights by category', (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_expandedInsightsApp());
    await tester.pumpAndSettle();
    await _scrollToPatternLibrary(tester);
    await tester.tap(find.text('Saúde'));
    await tester.pumpAndSettle();

    expect(
      find.text('Você tende a render menos após noites curtas'),
      findsOneWidget,
    );
    expect(
      find.text('Seu rendimento tende a ser maior pela manhã'),
      findsNothing,
    );
  });

  testWidgets('filters by severity and attention shortcut', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_expandedInsightsApp());
    await tester.pumpAndSettle();
    await _scrollToPatternLibrary(tester);
    await tester.tap(find.byKey(const ValueKey('summary-critico')));
    await tester.pump();
    expect(find.byType(InsightCard), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('summary-needs-attention')));
    await tester.pump();
    expect(find.byType(InsightCard), findsNWidgets(9));

    await tester.tap(find.byKey(const ValueKey('summary-needs-attention')));
    await tester.pump();
    expect(find.byType(InsightCard), findsNWidgets(17));
  });

  testWidgets('renders the evolution journey in its own view', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShadApp(home: InsightsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('view-evolucao')));
    await tester.pumpAndSettle();

    expect(find.text('Antes × agora'), findsOneWidget);
    expect(find.text('Da hipótese ao resultado'), findsOneWidget);
    expect(find.text('A história de cada disciplina'), findsOneWidget);
    expect(find.text('Histórico das mudanças'), findsOneWidget);
    expect(find.text('Detectado'), findsNWidgets(2));
    expect(find.text('Ação'), findsWidgets);
    expect(find.text('Melhora observada'), findsNWidgets(2));
    expect(find.byType(InsightCard), findsNothing);
  });

  testWidgets('combines category and subject filters', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_expandedInsightsApp());
    await tester.pumpAndSettle();
    await _scrollToPatternLibrary(tester);

    await tester.tap(find.text('Planejamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cálculo').first);
    await tester.pumpAndSettle();

    expect(
      find.text('Você costuma subestimar Cálculo em cerca de 40%'),
      findsOneWidget,
    );
    expect(
      find.text('78% do estudo para provas ocorre nas últimas 48h'),
      findsOneWidget,
    );
    expect(
      find.text('78% das suas tarefas recentes foram concluídas no prazo'),
      findsNothing,
    );
    expect(
      find.text('Seu rendimento tende a ser maior pela manhã'),
      findsNothing,
    );
  });

  testWidgets('shows the action only for actionable insights', (tester) async {
    var tapped = false;
    final actionable = getInsightsMock().firstWhere(
      (insight) => insight.tipo == 'melhor_horario',
    );
    final informational = getInsightsMock().firstWhere(
      (insight) => insight.tipo == 'duracao_ideal',
    );

    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                InsightCard(insight: actionable, onAction: () => tapped = true),
                InsightCard(insight: informational),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Agendar de manhã'), findsOneWidget);
    expect(find.byType(ShadButton), findsOneWidget);

    await tester.tap(find.text('Agendar de manhã'));
    expect(tapped, isTrue);
  });

  testWidgets('marks an insight as not useful and allows undo', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_expandedInsightsApp());
    await tester.pumpAndSettle();
    await _scrollToPatternLibrary(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('feedback-down-melhor_horario')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('feedback-down-melhor_horario')),
    );
    await tester.pump();

    expect(find.text('O que não bateu?'), findsOneWidget);
    expect(find.text('Semana atípica'), findsOneWidget);
    final reasonButton = tester.widget<ShadButton>(
      find.byKey(const ValueKey('feedback-reason-melhor_horario-Já resolvi')),
    );
    expect(reasonButton.hoverBackgroundColor, AppColors.surfaceMuted);
    expect(reasonButton.hoverForegroundColor, AppColors.textPrimary);

    await tester.tap(
      find.byKey(
        const ValueKey('feedback-reason-melhor_horario-Semana atípica'),
      ),
    );
    await tester.pump();

    expect(
      find.text('Seu rendimento tende a ser maior pela manhã'),
      findsOneWidget,
    );
    expect(find.text('Marcado como não útil · Semana atípica'), findsOneWidget);

    await tester.tap(find.text('Desfazer'));
    await tester.pump();

    expect(find.text('Isso faz sentido pra você?'), findsWidgets);
    expect(find.textContaining('Marcado como não útil'), findsNothing);
  });

  testWidgets('thanks the user after useful feedback', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_expandedInsightsApp());
    await tester.pumpAndSettle();
    await _scrollToPatternLibrary(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('feedback-up-melhor_horario')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('feedback-up-melhor_horario')));
    await tester.pump();

    expect(find.text('Valeu! Vamos priorizar insights assim.'), findsOneWidget);
  });

  testWidgets('shows a message when the selected category becomes empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final insights = ValueNotifier<List<Insight>>(getInsightsMock());
    addTearDown(insights.dispose);

    await tester.pumpWidget(
      ShadApp(
        home: ValueListenableBuilder<List<Insight>>(
          valueListenable: insights,
          builder: (context, value, _) {
            return InsightsScreen(
              key: const ValueKey('insights'),
              insights: value,
              initiallyShowPatternLibrary: true,
            );
          },
        ),
      ),
    );
    await _scrollToPatternLibrary(tester);
    await tester.tap(find.text('Saúde'));
    await tester.pumpAndSettle();

    insights.value = getInsightsMock()
        .where((insight) => insight.categoria == 'tempo')
        .toList();
    await tester.pumpAndSettle();

    expect(find.text('Nenhum insight em Saúde ainda.'), findsOneWidget);
  });

  testWidgets('uses two columns when wide and one column when narrow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_expandedInsightsApp());
    await tester.pumpAndSettle();
    await _scrollToPatternLibrary(tester);

    final outerScroll = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('melhor_dia_semana')),
      400,
      scrollable: outerScroll,
    );
    await tester.pumpAndSettle();

    final wideCards = find.byType(InsightCard);
    final wideFirst = tester.getTopLeft(wideCards.at(0));
    final wideSecond = tester.getTopLeft(wideCards.at(1));
    expect(wideFirst.dy, wideSecond.dy);
    expect(wideFirst.dx, isNot(wideSecond.dx));

    tester.view.physicalSize = const Size(500, 1200);
    await tester.pumpAndSettle();

    final narrowCards = find.byType(InsightCard);
    final narrowFirst = tester.getTopLeft(narrowCards.at(0));
    final narrowSecond = tester.getTopLeft(narrowCards.at(1));
    expect(narrowFirst.dx, narrowSecond.dx);
    expect(narrowSecond.dy, greaterThan(narrowFirst.dy));
  });
}
