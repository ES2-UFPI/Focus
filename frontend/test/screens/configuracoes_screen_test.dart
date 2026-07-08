import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/screens/configuracoes_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows data sync sources and simulates a connection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(ApiService()),
        child: const MaterialApp(home: ConfiguracoesScreen()),
      ),
    );

    expect(find.text('SINCRONIZAÇÃO E DADOS'), findsOneWidget);
    expect(find.text('Google Fit / Health Connect'), findsOneWidget);
    expect(find.text('Mi Fitness (Xiaomi)'), findsOneWidget);
    expect(find.text('Samsung Health'), findsOneWidget);
    expect(find.text('Apple Saúde (HealthKit)'), findsOneWidget);
    expect(find.text('Uso do celular / Tempo de tela'), findsOneWidget);

    await tester.tap(find.text('Conectar').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Integração em breve'), findsOneWidget);
    await tester.tap(find.text('Simular conexão'));
    await tester.pumpAndSettle();

    expect(find.text('Conectado'), findsOneWidget);
  });
}
