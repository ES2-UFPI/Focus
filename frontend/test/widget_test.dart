import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/api_service.dart';

void main() {
  testWidgets('FocusApp renders login screen when logged out', (WidgetTester tester) async {
    final apiService = ApiService();
    final authProvider = AuthProvider(apiService);

    await tester.pumpWidget(
      FocusApp(apiService: apiService, authProvider: authProvider),
    );

    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
