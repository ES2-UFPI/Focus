import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

enum _TipoAtividade { todos, prova, trabalho, entrega }

class AtividadesScreen extends StatefulWidget {
  const AtividadesScreen({super.key});

  @override
  State<AtividadesScreen> createState() => _AtividadesScreenState();
}

class _AtividadesScreenState extends State<AtividadesScreen> {
  _TipoAtividade _tipoSelecionado = _TipoAtividade.todos;
  bool _mostrarConcluidas = false;

  late final List<_AtividadeAcademica> _atividades = [
    _AtividadeAcademica(
      titulo: 'Prova de Cálculo I',
      disciplina: 'Cálculo I',
      tipo: _TipoAtividade.prova,
      data: DateTime.now().add(const Duration(days: 1)),
      descricao: 'Limites, derivadas e aplicações.',
      concluida: false,
    ),
    _AtividadeAcademica(
      titulo: 'Entrega do modelo ER',
      disciplina: 'Banco de Dados',
      tipo: _TipoAtividade.entrega,
      data: DateTime.now().add(const Duration(days: 3)),
      descricao: 'Diagrama entidade-relacionamento do projeto final.',
      concluida: false,
    ),
    _AtividadeAcademica(
      titulo: 'Trabalho de Física',
      disciplina: 'Física',
      tipo: _TipoAtividade.trabalho,
      data: DateTime.now().add(const Duration(days: 7)),
      descricao: 'Relatório sobre movimento retilíneo uniformemente variado.',
      concluida: false,
    ),
    _AtividadeAcademica(
      titulo: 'Apresentação de Programação II',
      disciplina: 'Prog. II',
      tipo: _TipoAtividade.trabalho,
      data: DateTime.now().add(const Duration(days: 12)),
      descricao: 'Demonstração da aplicação e decisões de arquitetura.',
      concluida: false,
    ),
    _AtividadeAcademica(
      titulo: 'Lista de exercícios de IA',
      disciplina: 'IA',
      tipo: _TipoAtividade.entrega,
      data: DateTime.now().subtract(const Duration(days: 2)),
      descricao: 'Busca heurística e algoritmos gulosos.',
      concluida: true,
    ),
  ];

  List<_AtividadeAcademica> get _atividadesFiltradas {
    final filtradas = _atividades.where((atividade) {
      final tipoOk = _tipoSelecionado == _TipoAtividade.todos || atividade.tipo == _tipoSelecionado;
      final statusOk = _mostrarConcluidas || !atividade.concluida;
      return tipoOk && statusOk;
    }).toList();

    filtradas.sort((a, b) => a.data.compareTo(b.data));
    return filtradas;
  }

  @override
  Widget build(BuildContext context) {
    final atividades = _atividadesFiltradas;

    return Container(
      color: AppColors.appBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: atividades.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: atividades.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _AtividadeCard(atividade: atividades[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final pendentes = _atividades.where((atividade) => !atividade.concluida).length;
    final proximas = _atividades.where((atividade) => !atividade.concluida && atividade.diasRestantes <= 3).length;

    return Material(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atividades Acadêmicas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Provas, trabalhos e entregas organizados por prazo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
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
                      value: '$proximas',
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
                _buildFilterChip(_TipoAtividade.todos, 'Todas'),
                _buildFilterChip(_TipoAtividade.prova, 'Provas'),
                _buildFilterChip(_TipoAtividade.trabalho, 'Trabalhos'),
                _buildFilterChip(_TipoAtividade.entrega, 'Entregas'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Mostrar concluídas'),
            value: _mostrarConcluidas,
            onChanged: (value) => setState(() => _mostrarConcluidas = value),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(_TipoAtividade tipo, String label) {
    final selected = _tipoSelecionado == tipo;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _tipoSelecionado = tipo),
      ),
    );
  }
}

class _AtividadeAcademica {
  final String titulo;
  final String disciplina;
  final _TipoAtividade tipo;
  final DateTime data;
  final String descricao;
  final bool concluida;

  const _AtividadeAcademica({
    required this.titulo,
    required this.disciplina,
    required this.tipo,
    required this.data,
    required this.descricao,
    required this.concluida,
  });

  int get diasRestantes {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final dataSemHora = DateTime(data.year, data.month, data.day);
    return dataSemHora.difference(hojeSemHora).inDays;
  }
}

class _AtividadeCard extends StatelessWidget {
  final _AtividadeAcademica atividade;

  const _AtividadeCard({required this.atividade});

  @override
  Widget build(BuildContext context) {
    final color = _tipoColor(atividade.tipo);

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
                color: atividade.concluida ? AppColors.neutral : color,
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
                        _TipoBadge(tipo: atividade.tipo),
                        const SizedBox(width: 8),
                        if (atividade.concluida)
                          const _StatusBadge(label: 'Concluída', color: AppColors.neutral),
                        const Spacer(),
                        Text(
                          _formatDate(atividade.data),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      atividade.titulo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      atividade.disciplina,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      atividade.descricao,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    _PrazoInfo(
                      diasRestantes: atividade.diasRestantes,
                      concluida: atividade.concluida,
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
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static Color _tipoColor(_TipoAtividade tipo) {
    return switch (tipo) {
      _TipoAtividade.prova => AppColors.dangerSoft,
      _TipoAtividade.trabalho => AppColors.subjectTeal,
      _TipoAtividade.entrega => AppColors.subjectIndigo,
      _TipoAtividade.todos => AppColors.neutral,
    };
  }
}

class _PrazoInfo extends StatelessWidget {
  final int diasRestantes;
  final bool concluida;

  const _PrazoInfo({
    required this.diasRestantes,
    required this.concluida,
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
    if (diasRestantes < 0) return ('Atrasada', AppColors.danger, Icons.error_outline_rounded);
    if (diasRestantes == 0) return ('Hoje', AppColors.dangerSoft, Icons.today_rounded);
    if (diasRestantes == 1) return ('Amanhã', AppColors.warningStrong, Icons.schedule_rounded);
    return ('Em $diasRestantes dias', AppColors.subjectIndigo, Icons.event_available_rounded);
  }
}

class _TipoBadge extends StatelessWidget {
  final _TipoAtividade tipo;

  const _TipoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (tipo) {
      _TipoAtividade.prova => ('Prova', AppColors.dangerSoft),
      _TipoAtividade.trabalho => ('Trabalho', AppColors.subjectTeal),
      _TipoAtividade.entrega => ('Entrega', AppColors.subjectIndigo),
      _TipoAtividade.todos => ('Atividade', AppColors.neutral),
    };

    return _StatusBadge(label: label, color: color);
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajuste os filtros para visualizar outras atividades.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
