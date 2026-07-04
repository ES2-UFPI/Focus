import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/insights_mock.dart';
import 'package:frontend/models/insights_model.dart';
import 'package:frontend/screens/insights_screen.dart';
import 'package:frontend/widgets/insight_card.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  testWidgets('renders mocked insights and category filters', (tester) async {
    await tester.pumpWidget(const ShadApp(home: InsightsScreen()));

    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Seus padrões'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Todas as matérias'), findsOneWidget);
    expect(find.text('Tempo'), findsOneWidget);
    expect(find.text('Saúde'), findsOneWidget);
    expect(find.textContaining('60% das sessões'), findsOneWidget);
    expect(find.text('Dados insuficientes'), findsOneWidget);
    expect(find.text('+41%'), findsOneWidget);
  });

  testWidgets('renders the empty insights state', (tester) async {
    await tester.pumpWidget(const ShadApp(home: InsightsScreen(insights: [])));

    expect(
      find.text('Estude algumas sessões para desbloquear seus insights.'),
      findsOneWidget,
    );
  });

  testWidgets('filters insights by category', (tester) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShadApp(home: InsightsScreen()));

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

  testWidgets('combines category and subject filters', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShadApp(home: InsightsScreen()));

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

  testWidgets('shows a message when the selected category becomes empty', (
    tester,
  ) async {
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
            );
          },
        ),
      ),
    );

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

    await tester.pumpWidget(const ShadApp(home: InsightsScreen()));

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
