import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  bool _notificacoesEmail = true;
  bool _notificacoesPush = true;
  bool _modoFocoEstrito = false;
  final Set<String> _fontesConectadas = {};

  static const _fontesSincronizacao = [
    _FonteSincronizacao(
      id: 'health_connect',
      nome: 'Google Fit / Health Connect',
      subtitulo: 'Android · sono e atividade',
      icone: Icons.health_and_safety_outlined,
    ),
    _FonteSincronizacao(
      id: 'mi_fitness',
      nome: 'Mi Fitness (Xiaomi)',
      subtitulo: 'Sono e passos',
      icone: Icons.watch_outlined,
    ),
    _FonteSincronizacao(
      id: 'samsung_health',
      nome: 'Samsung Health',
      subtitulo: 'Sono e atividade',
      icone: Icons.favorite_border_rounded,
    ),
    _FonteSincronizacao(
      id: 'apple_health',
      nome: 'Apple Saúde (HealthKit)',
      subtitulo: 'iOS · sono e atividade',
      icone: Icons.monitor_heart_outlined,
    ),
    _FonteSincronizacao(
      id: 'screen_time',
      nome: 'Uso do celular / Tempo de tela',
      subtitulo: 'Android · atividade antes das sessões',
      icone: Icons.phone_android_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final settingsTheme = ThemeData.light(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: AppColors.appBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimary,
        brightness: Brightness.light,
        primary: AppColors.brandPrimary,
        surface: AppColors.surface,
      ),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: AppColors.borderSubtle,
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.brandPrimary,
        textColor: AppColors.textPrimary,
        subtitleTextStyle: TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandPrimary;
          }
          return AppColors.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandPrimary.withValues(alpha: 0.28);
          }
          return AppColors.border;
        }),
      ),
    );

    return Theme(
      data: settingsTheme,
      child: Scaffold(
        backgroundColor: AppColors.appBackground,
        body: CustomScrollView(
          slivers: [
          SliverAppBar(
            expandedHeight: 132.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.appBackground,
            surfaceTintColor: AppColors.appBackground,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 24, bottom: 18),
              title: const Text(
                'Configurações',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 22,
                ),
              ),
              background: Container(
                color: AppColors.appBackground,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 32, bottom: 20),
                    child: Icon(
                      Icons.settings_suggest_rounded,
                      size: 82,
                      color: AppColors.brandPrimary.withValues(alpha: 0.10),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Perfil do Estudante (Resumo rápido)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Consumer<AuthProvider>(
                        builder: (_, auth, _) {
                          final inicial = auth.nomeAluno.isNotEmpty
                              ? auth.nomeAluno[0].toUpperCase()
                              : 'U';
                          return CircleAvatar(
                            radius: 32,
                            backgroundColor: const Color(0xFF673AB7),
                            child: Text(
                              inicial,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Consumer<AuthProvider>(
                          builder: (_, auth, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.nomeAluno.isNotEmpty ? auth.nomeAluno : 'Usuário',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                auth.emailAluno,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Icon(Icons.edit_outlined, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Seções de Opções
          SliverList(
            delegate: SliverChildListDelegate([
              // Prefs de Estudo
              _buildSectionTitle(context, 'Preferências de Estudo'),
              SwitchListTile(
                secondary: const Icon(Icons.psychology_outlined, color: Color(0xFF673AB7)),
                title: const Text('Modo Foco Estrito'),
                subtitle: const Text('Bloqueia navegação no aplicativo durante sessões de estudo.'),
                value: _modoFocoEstrito,
                onChanged: (val) {
                  setState(() => _modoFocoEstrito = val);
                },
              ),
              const Divider(height: 1, indent: 64),
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: Color(0xFF673AB7)),
                title: const Text('Tempo Padrão da Sessão'),
                subtitle: const Text('50 minutos (Pomodoro Padrão)'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {},
              ),

              // Notificações
              _buildSectionTitle(context, 'Notificações'),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined, color: Color(0xFF9C27B0)),
                title: const Text('Lembrete via Push'),
                subtitle: const Text('Alertar 15 minutos antes de iniciar um estudo ou evento.'),
                value: _notificacoesPush,
                onChanged: (val) {
                  setState(() => _notificacoesPush = val);
                },
              ),
              const Divider(height: 1, indent: 64),
              SwitchListTile(
                secondary: const Icon(Icons.mail_outline_rounded, color: Color(0xFF9C27B0)),
                title: const Text('Resumo Diário por E-mail'),
                subtitle: const Text('Receber relatórios semanais e agenda matinal por e-mail.'),
                value: _notificacoesEmail,
                onChanged: (val) {
                  setState(() => _notificacoesEmail = val);
                },
              ),

              // Integrações exclusivamente visuais nesta fase. A implementação
              // real usará Health Connect/HealthKit ou SDKs dos parceiros e
              // exigirá permissão e consentimento explícito do usuário.
              _buildSectionTitle(context, 'Sincronização e Dados'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Conecte apps de saúde para enriquecer seus insights com '
                  'sono, atividade e tempo de tela.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              ..._buildFontesSincronizacao(),


              // Sobre e Suporte
              _buildSectionTitle(context, 'Ajuda e Suporte'),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.grey),
                title: const Text('Sobre o Focus'),
                subtitle: const Text('Versão 1.0.0 — perfil do estudante'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.grey),
                title: const Text('Central de Ajuda / Feedback'),
                onTap: () {},
              ),

              _buildSectionTitle(context, 'Conta'),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text('Sair', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Sair'),
                      content: const Text('Deseja encerrar sua sessão?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sair', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                  if (confirmar == true && context.mounted) {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  }
                },
              ),

              const SizedBox(height: 120),
            ]),
          ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFontesSincronizacao() {
    final widgets = <Widget>[];

    for (var index = 0; index < _fontesSincronizacao.length; index++) {
      final fonte = _fontesSincronizacao[index];
      final conectada = _fontesConectadas.contains(fonte.id);

      widgets.add(
        ListTile(
          key: ValueKey('sync-source-${fonte.id}'),
          leading: Icon(fonte.icone, color: const Color(0xFF673AB7)),
          title: Text(fonte.nome),
          subtitle: Text(fonte.subtitulo),
          trailing: conectada
              ? Chip(
                  avatar: const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
                  label: const Text('Conectado'),
                  visualDensity: VisualDensity.compact,
                )
              : TextButton(
                  onPressed: () => _alternarFonte(fonte),
                  child: const Text('Conectar'),
                ),
          onTap: () => _alternarFonte(fonte),
        ),
      );

      if (index < _fontesSincronizacao.length - 1) {
        widgets.add(const Divider(height: 1, indent: 64));
      }
    }

    return widgets;
  }

  Future<void> _alternarFonte(_FonteSincronizacao fonte) async {
    if (_fontesConectadas.contains(fonte.id)) {
      setState(() => _fontesConectadas.remove(fonte.id));
      return;
    }

    final conectar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Conectar ${fonte.nome}'),
        content: const Text(
          'Integração em breve — protótipo. Esta ação apenas simula uma '
          'conexão e não acessa dados nem solicita permissões.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Agora não'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Simular conexão'),
          ),
        ],
      ),
    );

    if (conectar == true && mounted) {
      setState(() => _fontesConectadas.add(fonte.id));
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _FonteSincronizacao {
  final String id;
  final String nome;
  final String subtitulo;
  final IconData icone;

  const _FonteSincronizacao({
    required this.id,
    required this.nome,
    required this.subtitulo,
    required this.icone,
  });
}
