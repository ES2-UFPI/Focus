import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/insights_screen.dart';

void main() {
  testWidgets('renders mocked study profile insights', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: InsightsScreen()));

    expect(find.text('Perfil de Estudo'), findsOneWidget);
    expect(find.text('Seus padrões'), findsOneWidget);
    expect(find.textContaining('60% das sessões'), findsOneWidget);
    expect(find.text('Dados insuficientes'), findsOneWidget);
  });

  testWidgets('renders the empty insights state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: InsightsScreen(insights: [])),
    );

    expect(
      find.text('Estude algumas sessões para desbloquear seus insights.'),
      findsOneWidget,
    );
  });
}
