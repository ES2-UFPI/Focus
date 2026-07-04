import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/insights_mock.dart';
import 'package:frontend/screens/insight_detail_screen.dart';
import 'package:frontend/screens/insights_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  testWidgets('renders bar chart, evidence and metadata', (tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

  testWidgets('renders line chart for duration insight', (tester) async {
    final insight = getInsightsMock().firstWhere(
      (item) => item.tipo == 'duracao_ideal',
    );

    await tester.pumpWidget(
      ShadApp(home: InsightDetailScreen(insight: insight)),
    );

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('50 min'), findsOneWidget);
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

  testWidgets('opens detail from a grid card and weekly focus', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ShadApp(home: InsightsScreen()));
    await tester.pumpAndSettle();

    final gridCard = find.byKey(
      const ValueKey('insight-card-tap-melhor_horario'),
    );
    await tester.ensureVisible(gridCard);
    await tester.tap(gridCard);
    await tester.pumpAndSettle();

    expect(find.text('Detalhe do insight'), findsOneWidget);
    expect(
      find.text('Seu rendimento tende a ser maior pela manhã'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      const ShadApp(key: ValueKey('fresh-app'), home: InsightsScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('weekly-focus-card')));
    await tester.pumpAndSettle();

    expect(find.text('Detalhe do insight'), findsOneWidget);
    expect(
      find.text('60% das sessões de sexta à noite são canceladas'),
      findsOneWidget,
    );
  });
}
