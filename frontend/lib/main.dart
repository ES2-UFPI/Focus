import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'providers/agenda_provider.dart';
import 'providers/app_shell_provider.dart';
import 'providers/auth_provider.dart';
import 'services/api_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registro_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  final authProvider = AuthProvider(apiService);
  await authProvider.init();

  runApp(FocusApp(apiService: apiService, authProvider: authProvider));
}

class FocusApp extends StatelessWidget {
  final ApiService apiService;
  final AuthProvider authProvider;

  const FocusApp({
    super.key,
    required this.apiService,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppShellProvider()),
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => AgendaProvider()),
      ],
      child: ShadApp(
        title: 'Focus – Agenda Acadêmica',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),
        ],
        themeMode: ThemeMode.light,
        theme: ShadThemeData(
          brightness: Brightness.light,
          colorScheme: const ShadSlateColorScheme.light(),
        ),
        darkTheme: ShadThemeData(
          brightness: Brightness.dark,
          colorScheme: const ShadSlateColorScheme.dark(),
        ),
        builder: (context, child) => ScaffoldMessenger(child: child!),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/registro': (_) => const RegistroScreen(),
          '/home': (_) => const HomeScreen(),
        },
        home: authProvider.logado ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
}
