import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/agenda_model.dart';
import '../providers/agenda_provider.dart';
import '../services/agenda_service.dart';
import '../services/evento_service.dart';
import 'criar_evento_screen.dart';

enum _FiltroTipo { todos, prova, trabalho, seminario, apresentacao, outro }

class _TipoStyle {
  final String label;
  final Color color;
  final Color soft;

  const _TipoStyle(this.label, this.color, this.soft);
}

const Map<String, _TipoStyle> _tipoStyles = {
  'PROVA': _TipoStyle('Prova', Color(0xFFE53935), Color(0xFFFDEAEA)),
  'TRABALHO': _TipoStyle('Trabalho', Color(0xFFFFA726), Color(0xFFFFF4E5)),
  'SEMINARIO': _TipoStyle('Seminário', Color(0xFF7E57C2), Color(0xFFF1ECF9)),
  'APRESENTACAO':
      _TipoStyle('Apresentação', Color(0xFF42A5F5), Color(0xFFEAF4FD)),
  'OUTRO': _TipoStyle('Outro', Color(0xFF9E9E9E), Color(0xFFF2F2F2)),
};

_TipoStyle _tipoStyleOf(AgendaItem item) =>
    _tipoStyles[item.tipoEvento] ?? _tipoStyles['OUTRO']!;

class _AcademicTodo {
  final String title;
  final bool completed;

  const _AcademicTodo({
    required this.title,
    this.completed = false,
  });

  _AcademicTodo copyWith({
    String? title,
    bool? completed,
  }) {
    return _AcademicTodo(
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}

class AtividadesScreen extends StatefulWidget {
  const AtividadesScreen({super.key});

  @override
  State<AtividadesScreen> createState() => _AtividadesScreenState();
}

class _AtividadesScreenState extends State<AtividadesScreen> {
  static const double _wideBreakpoint = 900;

  _FiltroTipo _filtro = _FiltroTipo.todos;
  bool _mostrarConcluidas = false;
  final Map<String, List<_AcademicTodo>> _todosByEventId = {};
  final Set<String> _expandedIds = {};
  final EventoService _eventoService = EventoService();
  final Set<String> _concluindoIds = {};

  @override
  void initState() {
    super.initState();
    final provider = context.read<AgendaProvider>();
    Future.microtask(() => provider.fetchAgenda());
  }

  bool _tipoOk(AgendaItem e) {
    return _filtro == _FiltroTipo.todos ||
        (_filtro == _FiltroTipo.prova && e.tipoEvento == 'PROVA') ||
        (_filtro == _FiltroTipo.trabalho && e.tipoEvento == 'TRABALHO') ||
        (_filtro == _FiltroTipo.seminario && e.tipoEvento == 'SEMINARIO') ||
        (_filtro == _FiltroTipo.apresentacao &&
            e.tipoEvento == 'APRESENTACAO') ||
        (_filtro == _FiltroTipo.outro && e.tipoEvento == 'OUTRO');
  }

  List<AgendaItem> _pendentesFiltradas(List<AgendaItem> itens) {
    final filtrados = itens
        .where((i) => i.isEvento && i.concluido != true && _tipoOk(i))
        .toList();
    filtrados.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return filtrados;
  }

  List<AgendaItem> _concluidasFiltradas(List<AgendaItem> itens) {
    final filtrados = itens
        .where((i) => i.isEvento && i.concluido == true && _tipoOk(i))
        .toList();
    filtrados.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return filtrados;
  }

  bool _isAtrasada(AgendaItem e) =>
      e.urgencia == 'ATRASADO' || (e.diasRestantes ?? 0) < 0;

  Future<void> _abrirCriarEvento() async {
    final criado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CriarEventoScreen()),
    );
    if (criado == true && mounted) {
      context.read<AgendaProvider>().fetchAgenda();
    }
  }

  List<_AcademicTodo> _todosFor(AgendaItem evento) {
    return _todosByEventId.putIfAbsent(
      evento.id,
      () => <_AcademicTodo>[],
    );
  }

  Future<void> _definirConcluido(AgendaItem item, bool concluido) async {
    if (_concluindoIds.contains(item.id)) {
      return;
    }
    setState(() => _concluindoIds.add(item.id));

    try {
      await _eventoService.definirConcluido(
        eventoId: item.id,
        concluido: concluido,
      );
      if (!mounted) return;
      await context.read<AgendaProvider>().fetchAgenda(isRefresh: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            concluido
                ? '"${item.titulo}" marcada como concluída.'
                : '"${item.titulo}" voltou para pendentes.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } on AgendaServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar a atividade.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _concluindoIds.remove(item.id));
      }
    }
  }

  void _alternarExpandido(String eventId) {
    setState(() {
      if (!_expandedIds.remove(eventId)) {
        _expandedIds.add(eventId);
      }
    });
  }

  void _adicionarTodo(String eventId, String title) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return;
    }

    setState(() {
      final todos = _todosByEventId.putIfAbsent(eventId, () => []);
      todos.add(_AcademicTodo(title: trimmedTitle));
    });
  }

  void _alternarTodo(String eventId, int index, bool? completed) {
    final todos = _todosByEventId[eventId];
    if (todos == null || index < 0 || index >= todos.length) {
      return;
    }

    setState(() {
      todos[index] = todos[index].copyWith(completed: completed ?? false);
    });
  }

  void _removerTodo(String eventId, int index) {
    final todos = _todosByEventId[eventId];
    if (todos == null || index < 0 || index >= todos.length) {
      return;
    }

    setState(() {
      todos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AgendaProvider>(
      builder: (context, provider, _) {
        final pendentesFiltradas = _pendentesFiltradas(provider.itens);
        final concluidasFiltradas = _concluidasFiltradas(provider.itens);

        final pendentes = provider.itens
            .where((i) => i.isEvento && i.concluido != true)
            .length;
        final urgentes = provider.itens
            .where((i) =>
                i.isEvento &&
                i.concluido != true &&
                (i.diasRestantes ?? 999) <= 3)
            .length;
        final concluidas = provider.itens
            .where((i) => i.isEvento && i.concluido == true)
            .length;

        final atrasadas =
            pendentesFiltradas.where(_isAtrasada).toList();
        final estaSemana = pendentesFiltradas
            .where((e) =>
                !_isAtrasada(e) &&
                (e.diasRestantes ?? 999) >= 0 &&
                (e.diasRestantes ?? 999) <= 7)
            .toList();
        final depois = pendentesFiltradas
            .where((e) => !_isAtrasada(e) && (e.diasRestantes ?? 0) > 7)
            .toList();

        final temAtividades =
            pendentesFiltradas.isNotEmpty || concluidasFiltradas.isNotEmpty;

        return Container(
          color: AppColors.appBackground,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.isLoading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (provider.errorMessage != null)
                Expanded(
                  child: _ErrorState(
                    message: provider.errorMessage!,
                    onRetry: () => provider.fetchAgenda(),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.fetchAgenda(isRefresh: true),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide =
                            constraints.maxWidth >= _wideBreakpoint;
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            wide ? 32 : 16,
                            wide ? 28 : 16,
                            wide ? 32 : 16,
                            100,
                          ),
                          children: [
                            _buildHeader(context),
                            const SizedBox(height: 20),
                            _buildSummary(
                                pendentes, urgentes, concluidas, wide),
                            const SizedBox(height: 20),
                            _buildFilters(wide),
                            const SizedBox(height: 18),
                            if (!temAtividades)
                              _EmptyState(onAdd: _abrirCriarEvento)
                            else ...[
                              _buildGroups(
                                  atrasadas, estaSemana, depois, wide),
                              if (_mostrarConcluidas &&
                                  concluidasFiltradas.isNotEmpty) ...[
                                const SizedBox(height: 26),
                                _buildConcluidas(concluidasFiltradas),
                              ],
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atividades Acadêmicas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'O que precisa sair do papel, organizado por urgência.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: AppColors.brandPrimary,
          borderRadius: BorderRadius.circular(12),
          elevation: 3,
          shadowColor: AppColors.brandPrimary.withValues(alpha: 0.4),
          child: InkWell(
            onTap: _abrirCriarEvento,
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Tooltip(
                message: 'Nova atividade',
                child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(int pendentes, int urgentes, int concluidas, bool wide) {
    final tiles = [
      _SummaryTile(
        label: 'Pendentes',
        value: '$pendentes',
        icon: Icons.assignment_outlined,
        color: AppColors.brandPrimary,
        soft: const Color(0xFFEEF0FE),
      ),
      _SummaryTile(
        label: 'Até 3 dias',
        value: '$urgentes',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFE53935),
        soft: const Color(0xFFFDEAEA),
        valueColor: const Color(0xFFE53935),
      ),
      _SummaryTile(
        label: 'Concluídas',
        value: '$concluidas',
        icon: Icons.check_rounded,
        color: const Color(0xFF4CAF50),
        soft: const Color(0xFFE9F6EA),
      ),
    ];

    if (wide) {
      return Row(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(child: tiles[i]),
          ],
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 10),
            Expanded(child: tiles[1]),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: tiles[2])]),
      ],
    );
  }

  Widget _buildFilters(bool wide) {
    final chips = SingleChildScrollView(
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
    );

    final toggle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Mostrar concluídas',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Switch(
          value: _mostrarConcluidas,
          activeThumbColor: Colors.white,
          activeTrackColor: AppColors.brandPrimary,
          onChanged: (v) => setState(() => _mostrarConcluidas = v),
        ),
      ],
    );

    if (wide) {
      return Row(
        children: [
          Expanded(child: chips),
          const SizedBox(width: 14),
          toggle,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chips,
        Align(alignment: Alignment.centerRight, child: toggle),
      ],
    );
  }

  Widget _chip(_FiltroTipo tipo, String label) {
    final selected = _filtro == tipo;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: () => setState(() => _filtro = tipo),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? const Color(0xFF1A1A2E)
                    : const Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroups(
    List<AgendaItem> atrasadas,
    List<AgendaItem> estaSemana,
    List<AgendaItem> depois,
    bool wide,
  ) {
    final groups = [
      _GroupData(
        title: 'Atrasadas',
        dot: const Color(0xFFE53935),
        soft: const Color(0xFFFDEAEA),
        items: atrasadas,
      ),
      _GroupData(
        title: 'Esta semana',
        dot: const Color(0xFFF9A825),
        soft: const Color(0xFFFFF4E5),
        items: estaSemana,
      ),
      _GroupData(
        title: 'Depois',
        dot: AppColors.brandPrimary,
        soft: const Color(0xFFEEF0FE),
        items: depois,
      ),
    ];

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < groups.length; i++) ...[
            if (i > 0) const SizedBox(width: 18),
            Expanded(child: _buildGroup(groups[i])),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          if (i > 0) const SizedBox(height: 22),
          _buildGroup(groups[i]),
        ],
      ],
    );
  }

  Widget _buildGroup(_GroupData group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: group.dot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                group.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 9),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: group.soft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${group.items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: group.dot,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (group.items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
            ),
            child: const Text(
              'Nada por aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          )
        else
          for (var i = 0; i < group.items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildAtividadeCard(group.items[i]),
          ],
      ],
    );
  }

  Widget _buildAtividadeCard(AgendaItem item) {
    final todos = _todosFor(item);
    return _AtividadeCard(
      item: item,
      todos: todos,
      expanded: _expandedIds.contains(item.id),
      concluindo: _concluindoIds.contains(item.id),
      onConcluir: () => _definirConcluido(item, true),
      onToggleExpand: () => _alternarExpandido(item.id),
      onAddTodo: (title) => _adicionarTodo(item.id, title),
      onToggleTodo: (index, completed) =>
          _alternarTodo(item.id, index, completed),
      onRemoveTodo: (index) => _removerTodo(item.id, index),
    );
  }

  Widget _buildConcluidas(List<AgendaItem> concluidas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'Concluídas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 9),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F6EA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${concluidas.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < concluidas.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _ConcluidaTile(
            item: concluidas[i],
            revertendo: _concluindoIds.contains(concluidas[i].id),
            onReverter: () => _definirConcluido(concluidas[i], false),
          ),
        ],
      ],
    );
  }
}

class _GroupData {
  final String title;
  final Color dot;
  final Color soft;
  final List<AgendaItem> items;

  const _GroupData({
    required this.title,
    required this.dot,
    required this.soft,
    required this.items,
  });
}

class _AtividadeCard extends StatefulWidget {
  final AgendaItem item;
  final List<_AcademicTodo> todos;
  final bool expanded;
  final bool concluindo;
  final VoidCallback onConcluir;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onAddTodo;
  final void Function(int index, bool? completed) onToggleTodo;
  final void Function(int index) onRemoveTodo;

  const _AtividadeCard({
    required this.item,
    required this.todos,
    required this.expanded,
    required this.concluindo,
    required this.onConcluir,
    required this.onToggleExpand,
    required this.onAddTodo,
    required this.onToggleTodo,
    required this.onRemoveTodo,
  });

  @override
  State<_AtividadeCard> createState() => _AtividadeCardState();
}

class _AtividadeCardState extends State<_AtividadeCard> {
  final TextEditingController _draftController = TextEditingController();

  @override
  void dispose() {
    _draftController.dispose();
    super.dispose();
  }

  void _adicionar() {
    final title = _draftController.text.trim();
    if (title.isEmpty) {
      return;
    }
    widget.onAddTodo(title);
    _draftController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tipo = _tipoStyleOf(item);
    final total = widget.todos.length;
    final done = widget.todos.where((t) => t.completed).length;
    final pct = total > 0 ? done / total : 0.0;
    final progressColor = pct >= 1.0 ? const Color(0xFF4CAF50) : tipo.color;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: tipo.color, width: 4),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Tooltip(
                    message: 'Marcar como concluída',
                    child: InkWell(
                      onTap: widget.concluindo ? null : widget.onConcluir,
                      borderRadius: BorderRadius.circular(999),
                      child: widget.concluindo
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF4CAF50),
                              ),
                            )
                          : Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFD1D5DB),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 13,
                                color: Color(0xFFD1D5DB),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(child: _TipoBadge(tipo: tipo)),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(item.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                item.titulo,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.disciplinaNome,
                style: const TextStyle(
                  fontSize: 13,
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
                urgencia: item.urgencia,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFEEEEEE),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$done/$total',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: widget.onToggleExpand,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 9, 4, 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.checklist_rounded,
                        size: 15,
                        color: AppColors.brandPrimary,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'To-do',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: widget.expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.expanded) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFF0F0F3)),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < widget.todos.length; i++)
                        Padding(
                          padding: EdgeInsets.only(top: i > 0 ? 7 : 0),
                          child: _TodoRow(
                            todo: widget.todos[i],
                            tipo: tipo,
                            onToggle: () => widget.onToggleTodo(
                              i,
                              !widget.todos[i].completed,
                            ),
                            onRemove: () => widget.onRemoveTodo(i),
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: widget.todos.isEmpty ? 0 : 11,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _draftController,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _adicionar(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Adicionar tarefa...',
                                  hintStyle: const TextStyle(
                                    color: AppColors.textMuted,
                                  ),
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.brandPrimary,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: const Color(0xFFEEF0FE),
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: _adicionar,
                                borderRadius: BorderRadius.circular(8),
                                child: const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 18,
                                    color: AppColors.brandPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
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

class _TodoRow extends StatelessWidget {
  final _AcademicTodo todo;
  final _TipoStyle tipo;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _TodoRow({
    required this.todo,
    required this.tipo,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              color: todo.completed ? tipo.color : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: todo.completed ? tipo.color : const Color(0xFFD1D5DB),
                width: 1.5,
              ),
            ),
            child: todo.completed
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            todo.title,
            style: TextStyle(
              fontSize: 13.5,
              color: todo.completed
                  ? AppColors.textMuted
                  : AppColors.textSecondary,
              decoration:
                  todo.completed ? TextDecoration.lineThrough : null,
              decorationColor: AppColors.textMuted,
            ),
          ),
        ),
        InkWell(
          onTap: onRemove,
          borderRadius: BorderRadius.circular(6),
          child: const SizedBox(
            width: 22,
            height: 22,
            child: Icon(
              Icons.close_rounded,
              size: 15,
              color: Color(0xFFBDBDBD),
            ),
          ),
        ),
      ],
    );
  }
}

class _TipoBadge extends StatelessWidget {
  final _TipoStyle tipo;

  const _TipoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: tipo.soft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          tipo.label.toUpperCase(),
          style: TextStyle(
            color: tipo.color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class _ConcluidaTile extends StatelessWidget {
  final AgendaItem item;
  final bool revertendo;
  final VoidCallback onReverter;

  const _ConcluidaTile({
    required this.item,
    required this.revertendo,
    required this.onReverter,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = _tipoStyleOf(item);
    return Opacity(
      opacity: 0.75,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Tooltip(
              message: 'Voltar para pendentes',
              child: InkWell(
                onTap: revertendo ? null : onReverter,
                borderRadius: BorderRadius.circular(999),
                child: revertendo
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4CAF50),
                        ),
                      )
                    : const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: Color(0xFF4CAF50),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            _TipoBadge(tipo: tipo),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Color(0xFFBDBDBD),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              item.disciplinaNome,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrazoInfo extends StatelessWidget {
  final int diasRestantes;
  final String? urgencia;

  const _PrazoInfo({
    required this.diasRestantes,
    this.urgencia,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = _prazoData();
    return Row(
      children: [
        Icon(Icons.schedule_rounded, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  (String, Color) _prazoData() {
    if (urgencia == 'ATRASADO' || diasRestantes < 0) {
      final dias = diasRestantes.abs();
      final label = dias > 0
          ? 'Atrasado há $dias ${dias == 1 ? 'dia' : 'dias'}'
          : 'Atrasado';
      return (label, const Color(0xFFE53935));
    }
    if (diasRestantes == 0) {
      return ('Hoje', const Color(0xFFF9A825));
    }
    if (diasRestantes == 1) {
      return ('Amanhã', const Color(0xFFF9A825));
    }
    if (diasRestantes <= 3) {
      return ('Em $diasRestantes dias', const Color(0xFFF9A825));
    }
    return ('Em $diasRestantes dias', AppColors.textMuted);
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color soft;
  final Color? valueColor;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.soft,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
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
