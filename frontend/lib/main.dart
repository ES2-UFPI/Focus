import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'providers/agenda_provider.dart';
import 'providers/app_shell_provider.dart';
import 'providers/materiais_provider.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registro_screen.dart';

void main() {
  runApp(const FocusApp());
}

class FocusApp extends StatelessWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppShellProvider()),
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider(create: (_) => AgendaProvider()),
        ChangeNotifierProvider(create: (_) => MateriaisProvider()),
      ],
      child: ShadApp(
        title: 'Focus – Agenda Acadêmica',
        debugShowCheckedModeBanner: false,
        theme: ShadThemeData(
          brightness: Brightness.light,
          colorScheme: const ShadSlateColorScheme.light(),
        ),
        darkTheme: ShadThemeData(
          brightness: Brightness.dark,
          colorScheme: const ShadSlateColorScheme.dark(),
        ),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/registro': (_) => const RegistroScreen(),
          '/home': (_) => const HomeScreen(),
        },
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.carregando) {
      return const Scaffold(
        backgroundColor: Color(0xFF0f0e17),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366f1)),
        ),
      );
    }

    if (auth.logado) return const HomeScreen();
    return const LoginScreen();
  }
}
