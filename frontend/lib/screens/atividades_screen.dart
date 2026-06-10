import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/agenda_model.dart';
import '../providers/agenda_provider.dart';
import 'criar_evento_screen.dart';

enum _FiltroTipo { todos, prova, trabalho, seminario, apresentacao, outro }

class AtividadesScreen extends StatefulWidget {
  const AtividadesScreen({super.key});

  @override
  State<AtividadesScreen> createState() => _AtividadesScreenState();
}

class _AtividadesScreenState extends State<AtividadesScreen> {
  _FiltroTipo _filtro = _FiltroTipo.todos;
  bool _mostrarConcluidas = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AgendaProvider>();
    Future.microtask(() => provider.fetchAgenda());
  }

  List<AgendaItem> _filtrar(List<AgendaItem> todos) {
    final eventos = todos.where((i) => i.isEvento).toList();
    final filtrados = eventos.where((e) {
      final tipoOk = _filtro == _FiltroTipo.todos ||
          (_filtro == _FiltroTipo.prova && e.tipoEvento == 'PROVA') ||
          (_filtro == _FiltroTipo.trabalho && e.tipoEvento == 'TRABALHO') ||
          (_filtro == _FiltroTipo.seminario && e.tipoEvento == 'SEMINARIO') ||
          (_filtro == _FiltroTipo.apresentacao && e.tipoEvento == 'APRESENTACAO') ||
          (_filtro == _FiltroTipo.outro && e.tipoEvento == 'OUTRO');
      final statusOk = _mostrarConcluidas || e.concluido != true;
      return tipoOk && statusOk;
    }).toList();
    filtrados.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return filtrados;
  }

  Future<void> _abrirCriarEvento() async {
    final criado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CriarEventoScreen()),
    );
    if (criado == true && mounted) {
      context.read<AgendaProvider>().fetchAgenda();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AgendaProvider>(
      builder: (context, provider, _) {
        final atividades = _filtrar(provider.itens);
        final pendentes = provider.itens
            .where((i) => i.isEvento && i.concluido != true)
            .length;
        final urgentes = provider.itens
            .where((i) => i.isEvento && i.concluido != true &&
                (i.diasRestantes ?? 999) <= 3)
            .length;

        return Container(
          color: AppColors.appBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, pendentes, urgentes),
              _buildFilters(),
              if (provider.isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (provider.errorMessage != null)
                Expanded(child: _ErrorState(
                  message: provider.errorMessage!,
                  onRetry: () => provider.fetchAgenda(),
                ))
              else if (atividades.isEmpty)
                Expanded(child: _EmptyState(onAdd: _abrirCriarEvento))
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.fetchAgenda(isRefresh: true),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: atividades.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _EventoCard(item: atividades[i]),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int pendentes, int urgentes) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Atividades Acadêmicas',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  IconButton(
                    onPressed: _abrirCriarEvento,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: AppColors.subjectIndigo,
                    tooltip: 'Adicionar atividade',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Provas, trabalhos e compromissos organizados por prazo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: 'Pendentes',
                      value: '$pendentes',
                      icon: Icons.pending_actions_rounded,
                      color: AppColors.subjectIndigo,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Até 3 dias',
                      value: '$urgentes',
                      icon: Icons.priority_high_rounded,
                      color: AppColors.warningStrong,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(_FiltroTipo.todos, 'Todas'),
                _chip(_FiltroTipo.prova, 'Provas'),
                _chip(_FiltroTipo.trabalho, 'Trabalhos'),
                _chip(_FiltroTipo.seminario, 'Seminários'),
                _chip(_FiltroTipo.apresentacao, 'Apresentações'),
                _chip(_FiltroTipo.outro, 'Outros'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Mostrar concluídas'),
            value: _mostrarConcluidas,
            onChanged: (v) => setState(() => _mostrarConcluidas = v),
          ),
        ],
      ),
    );
  }

  Widget _chip(_FiltroTipo tipo, String label) {
    final selected = _filtro == tipo;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filtro = tipo),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card de evento
// ---------------------------------------------------------------------------

class _EventoCard extends StatelessWidget {
  final AgendaItem item;
  const _EventoCard({required this.item});

  static const _tipoColors = {
    'PROVA': AppColors.dangerSoft,
    'TRABALHO': AppColors.subjectTeal,
    'SEMINARIO': Color(0xFF8B5CF6),
    'APRESENTACAO': Color(0xFF0EA5E9),
    'OUTRO': AppColors.neutral,
  };

  static const _tipoLabels = {
    'PROVA': 'Prova',
    'TRABALHO': 'Trabalho',
    'SEMINARIO': 'Seminário',
    'APRESENTACAO': 'Apresentação',
    'OUTRO': 'Outro',
  };

  @override
  Widget build(BuildContext context) {
    final cor = _tipoColors[item.tipoEvento] ?? AppColors.neutral;
    final label = _tipoLabels[item.tipoEvento] ?? 'Atividade';
    final concluido = item.concluido == true;

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: concluido ? AppColors.neutral : cor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadii.lg),
                  bottomLeft: Radius.circular(AppRadii.lg),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Badge(label: label, color: concluido ? AppColors.neutral : cor),
                        const SizedBox(width: 8),
                        if (concluido)
                          const _Badge(label: 'Concluída', color: AppColors.neutral),
                        const Spacer(),
                        Text(
                          _formatDate(item.timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.titulo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.disciplinaNome,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    if (item.descricao != null && item.descricao!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.descricao!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _PrazoInfo(
                      diasRestantes: item.diasRestantes ?? 0,
                      concluida: concluido,
                      urgencia: item.urgencia,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PrazoInfo extends StatelessWidget {
  final int diasRestantes;
  final bool concluida;
  final String? urgencia;

  const _PrazoInfo({
    required this.diasRestantes,
    required this.concluida,
    this.urgencia,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _prazoData();
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  (String, Color, IconData) _prazoData() {
    if (concluida) return ('Finalizada', AppColors.neutral, Icons.check_circle_outline_rounded);
    if (urgencia == 'ATRASADO' || diasRestantes < 0) {
      return ('Atrasada', AppColors.danger, Icons.error_outline_rounded);
    }
    if (diasRestantes == 0) return ('Hoje', AppColors.dangerSoft, Icons.today_rounded);
    if (diasRestantes == 1) return ('Amanhã', AppColors.warningStrong, Icons.schedule_rounded);
    return ('Em $diasRestantes dias', AppColors.subjectIndigo, Icons.event_available_rounded);
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares
// ---------------------------------------------------------------------------

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma atividade encontrada.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre provas, trabalhos e outros compromissos.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar atividade'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
