import 'package:flutter/material.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  bool _notificacoesEmail = true;
  bool _notificacoesPush = true;
  bool _modoFocoEstrito = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header Estilizado com Gradiente
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Configurações',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                  fontSize: 20,
                  shadows: const [
                    Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 4),
                  ],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF673AB7), Color(0xFF9C27B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40.0),
                    child: Icon(
                      Icons.settings_suggest_rounded,
                      size: 80,
                      color: Colors.white24,
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
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Color(0xFF673AB7),
                        child: Text(
                          'EF',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estudante Focus',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'estudante@focus.com',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_outlined, color: Colors.grey),
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

              // Tema e Aparência
              _buildSectionTitle(context, 'Aparência e Tema'),
              ListTile(
                leading: const Icon(Icons.palette_outlined, color: Colors.blueGrey),
                title: const Text('Tema da Interface'),
                subtitle: const Text('Claro (Sistema)'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Claro'),
                      selected: true,
                      onSelected: (_) {},
                    ),
                    ChoiceChip(
                      label: const Text('Escuro'),
                      selected: false,
                      onSelected: (_) {},
                    ),
                  ],
                ),
              ),

              // Sobre e Suporte
              _buildSectionTitle(context, 'Ajuda e Suporte'),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.grey),
                title: const Text('Sobre o Focus'),
                subtitle: const Text('Versão 1.0.0 — ES2'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.grey),
                title: const Text('Central de Ajuda / Feedback'),
                onTap: () {},
              ),

              const SizedBox(height: 120),
            ]),
          ),
        ],
      ),
    );
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
