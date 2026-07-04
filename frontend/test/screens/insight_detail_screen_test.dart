import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/insights_mock.dart';
import 'package:frontend/screens/insight_detail_screen.dart';
import 'package:frontend/screens/insights_screen.dart';
import 'package:frontend/widgets/insights/insight_feedback_control.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void _configureLargeView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('renders annotated bar chart, evidence and metadata', (
    tester,
  ) async {
    _configureLargeView(tester);
    final insight = getInsightsMock().firstWhere(
      (item) => item.tipo == 'melhor_horario',
    );
    var actionTapped = false;

    await tester.pumpWidget(
      ShadApp(
        home: InsightDetailScreen(
          insight: insight,
          onAction: () => actionTapped = true,
        ),
      ),
    );

    expect(find.text('Detalhe do insight'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.byKey(const ValueKey('chart-callout')), findsOneWidget);
    expect(find.text('9-12h · 4,2'), findsOneWidget);
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.alignment, BarChartAlignment.spaceEvenly);
    expect(chart.data.extraLinesData.horizontalLines, hasLength(1));
    expect(chart.data.extraLinesData.horizontalLines.single.dashArray, [4, 4]);

    expect(find.text('Sessões que sustentam o padrão'), findsOneWidget);
    expect(find.text('18 sessões na amostra'), findsOneWidget);
    expect(find.text('Confiança alta'), findsOneWidget);
    expect(find.text('18/06/2026'), findsOneWidget);
    expect(find.text('Recomendação observacional'), findsOneWidget);
    expect(find.text('Isso faz sentido pra você?'), findsOneWidget);

    final action = find.byKey(const ValueKey('detail-action-melhor_horario'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    expect(actionTapped, isTrue);
  });

  testWidgets('renders an annotated line chart', (tester) async {
    final insight = getInsightsMock().firstWhere(
      (item) => item.tipo == 'duracao_ideal',
    );

    await tester.pumpWidget(
      ShadApp(home: InsightDetailScreen(insight: insight)),
    );

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.byKey(const ValueKey('chart-callout')), findsOneWidget);
    expect(find.text('50 min · 4,1'), findsOneWidget);
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.extraLinesData.horizontalLines, hasLength(1));
  });

  testWidgets('falls back to numbers when chart and evidence are absent', (
    tester,
  ) async {
    final insight = getInsightsMock().firstWhere(
      (item) => item.tipo == 'tarefas_no_prazo',
    );

    await tester.pumpWidget(
      ShadApp(home: InsightDetailScreen(insight: insight)),
    );

    expect(find.text('Números observados'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
    expect(find.byType(LineChart), findsNothing);
    expect(
      find.textContaining('As sessões individuais ainda não estão disponíveis'),
      findsOneWidget,
    );
  });

  testWidgets('opens detail from a feed row', (tester) async {
    _configureLargeView(tester);
    await tester.pumpWidget(
      ShadApp(home: InsightsScreen(insights: getInsightsMock())),
    );
    await tester.pump();

    final row = find.byKey(const ValueKey('feed-row-melhor_horario'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.text('Detalhe do insight'), findsOneWidget);
    expect(
      find.text('Seu rendimento tende a ser maior pela manhã'),
      findsOneWidget,
    );
  });

  testWidgets('reports feedback changes from the detail', (tester) async {
    _configureLargeView(tester);
    final insight = getInsightsMock().first;
    InsightFeedbackState? feedback;

    await tester.pumpWidget(
      ShadApp(
        home: InsightDetailScreen(
          insight: insight,
          onFeedbackChanged: (value) => feedback = value,
        ),
      ),
    );

    final button = find.byKey(
      const ValueKey('feedback-up-detail-melhor_horario'),
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();

    expect(feedback?.status, InsightFeedbackStatus.useful);
    expect(find.text('Valeu! Vamos priorizar insights assim.'), findsOneWidget);
  });
}
