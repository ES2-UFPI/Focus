import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/agenda_provider.dart';
import 'screens/agenda_screen.dart';

void main() {
  runApp(const FocusApp());
}

class FocusApp extends StatelessWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AgendaProvider()),
      ],
      child: MaterialApp(
        title: 'Focus – Agenda Acadêmica',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5C6BC0), // indigo
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const AgendaScreen(),
      ),
    );
  }
}
