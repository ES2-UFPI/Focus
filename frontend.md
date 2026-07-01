2. Frontend (Flutter/Dart)

Stack: Flutter + Provider (state management), http (client REST), shared_preferences (persistência do token), shadcn_ui (componentes), fl_chart (gráficos), intl (pt_BR).

lib/
├── main.dart                 # entrypoint, MultiProvider, rotas /login /registro /home
├── core/
│   ├── network/api_client.dart   # base URL, headers com Authorization: Token
│   └── theme/app_theme.dart
├── models/                   # Disciplina, MaterialEstudo, BlocoEstudo, AgendaItem, AgendaRecomendacao
├── services/                 # camada HTTP: auth, disciplina, evento, sessao_estudo, agenda, api_service
├── providers/                # ChangeNotifier: AuthProvider, AgendaProvider, MateriaisProvider, AppShellProvider
├── screens/                  # login, registro, home (shell 4 abas), agenda, atividades, materiais, relatorios, consistencia, configuracoes, criar_evento, criar_sessao
├── widgets/                  # componentes reutilizáveis (cards, timeline, sidebar, dialogs)
└── pages/
    └── biblioteca_materiais_page.dart

Organização: arquitetura em camadas (services → providers → screens → widgets), não por feature. Base URL: http://localhost:8000/api. Token salvo em SharedPreferences e injetado em todo request via defaultHeaders.

Navegação: bottom navigation com 4 abas (Atividades, Agenda, Consistência, Configurações) controlada por AppShellProvider; rotas nomeadas para login/registro; HomeScreen decide entre LoginScreen/shell principal conforme sessão restaurada no main.dart.
