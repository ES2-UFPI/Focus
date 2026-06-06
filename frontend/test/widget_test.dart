import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('FocusApp renders AgendaScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const FocusApp());

    // Verifica que a tela de agenda é exibida com o título correto.
    expect(find.text('Agenda Acadêmica'), findsOneWidget);
  });
}
