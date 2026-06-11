import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/agenda_model.dart';
import '../providers/agenda_provider.dart';
import 'criar_evento_screen.dart';

enum _FiltroTipo { todos, prova, trabalho, seminario, apresentacao, outro }

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
  _FiltroTipo _filtro = _FiltroTipo.todos;
  bool _mostrarConcluidas = false;
  final Map<String, List<_AcademicTodo>> _todosByEventId = {};

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
          (_filtro == _FiltroTipo.apresentacao &&
              e.tipoEvento == 'APRESENTACAO') ||
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

  List<_AcademicTodo> _todosFor(AgendaItem evento) {
    return _todosByEventId.putIfAbsent(
      evento.id,
      () => <_AcademicTodo>[],
    );
  }

  void _abrirTodoList(AgendaItem evento) {
    _todosFor(evento);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (context) {
        return _EventTodoSheet(
          evento: evento,
          todos: _todosFor(evento),
          onAdd: (title) => _adicionarTodo(evento.id, title),
          onToggle: (index, completed) => _alternarTodo(
            evento.id,
            index,
            completed,
          ),
          onRemove: (index) => _removerTodo(evento.id, index),
        );
      },
    );
  }

  void _adicionarTodo(String eventId, String title) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return;
    }

    setState(() {
      final todos = _todosByEventId.putIfAbsent(eventId, () => []);
      todos.insert(0, _AcademicTodo(title: trimmedTitle));
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
        final atividades = _filtrar(provider.itens);
        final pendentes = provider.itens
            .where((i) => i.isEvento && i.concluido != true)
            .length;
        final urgentes = provider.itens
            .where((i) =>
                i.isEvento &&
                i.concluido != true &&
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
                Expanded(
                  child: _ErrorState(
                    message: provider.errorMessage!,
                    onRetry: () => provider.fetchAgenda(),
                  ),
                )
              else if (atividades.isEmpty)
                Expanded(child: _EmptyState(onAdd: _abrirCriarEvento))
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.fetchAgenda(isRefresh: true),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: atividades.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final todos = _todosFor(atividades[i]);
                        return _EventoCard(
                          item: atividades[i],
                          todoCount: todos.length,
                          completedTodoCount:
                              todos.where((todo) => todo.completed).length,
                          onOpenTodos: () => _abrirTodoList(atividades[i]),
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

class _EventTodoSheet extends StatefulWidget {
  final AgendaItem evento;
  final List<_AcademicTodo> todos;
  final ValueChanged<String> onAdd;
  final void Function(int index, bool? completed) onToggle;
  final void Function(int index) onRemove;

  const _EventTodoSheet({
    required this.evento,
    required this.todos,
    required this.onAdd,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  State<_EventTodoSheet> createState() => _EventTodoSheetState();
}

class _EventTodoSheetState extends State<_EventTodoSheet> {
  final TextEditingController _controller = TextEditingController();

  void _adicionar() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      return;
    }

    widget.onAdd(title);
    setState(() {
      _controller.clear();
    });
  }

  void _alternar(int index, bool? completed) {
    widget.onToggle(index, completed);
    setState(() {});
  }

  void _remover(int index) {
    widget.onRemove(index);
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final pendingCount = widget.todos.where((todo) => !todo.completed).length;
    final completedCount = widget.todos.length - pendingCount;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.subjectTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      color: AppColors.subjectTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To-do List',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.evento.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$pendingCount pendentes - $completedCount concluídas',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _adicionar(),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Adicionar tarefa deste evento',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _adicionar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: AppColors.textInverted,
                      minimumSize: const Size(48, 48),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                    ),
                    child: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: widget.todos.isEmpty
                    ? _TodoEmptyState(eventTitle: widget.evento.titulo)
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: widget.todos.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          return _TodoTile(
                            todo: widget.todos[index],
                            onChanged: (value) => _alternar(index, value),
                            onRemove: () => _remover(index),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodoEmptyState extends StatelessWidget {
  final String eventTitle;

  const _TodoEmptyState({required this.eventTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text(
        'Nenhuma tarefa adicionada para "$eventTitle".',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  final _AcademicTodo todo;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onRemove;

  const _TodoTile({
    required this.todo,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        todo.completed ? AppColors.textMuted : AppColors.textPrimary;
    final backgroundColor = todo.completed
        ? AppColors.success.withValues(alpha: 0.08)
        : AppColors.appBackground;
    final borderColor = todo.completed
        ? AppColors.success.withValues(alpha: 0.28)
        : AppColors.borderSubtle;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Checkbox(
            value: todo.completed,
            onChanged: onChanged,
            activeColor: AppColors.success,
          ),
          Expanded(
            child: Text(
              todo.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight:
                        todo.completed ? FontWeight.w500 : FontWeight.w700,
                    decoration:
                        todo.completed ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textMuted,
                  ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.dangerSoft,
            tooltip: 'Remover tarefa',
          ),
        ],
      ),
    );
  }
}

class _EventoCard extends StatelessWidget {
  final AgendaItem item;
  final int todoCount;
  final int completedTodoCount;
  final VoidCallback onOpenTodos;

  const _EventoCard({
    required this.item,
    required this.todoCount,
    required this.completedTodoCount,
    required this.onOpenTodos,
  });

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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    Row(
                      children: [
                        Expanded(
                          child: _PrazoInfo(
                            diasRestantes: item.diasRestantes ?? 0,
                            concluida: concluido,
                            urgencia: item.urgencia,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: onOpenTodos,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.brandPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          icon: const Icon(Icons.checklist_rounded, size: 18),
                          label: Text('To-do ($completedTodoCount/$todoCount)'),
                        ),
                      ],
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
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }

  (String, Color, IconData) _prazoData() {
    if (concluida) {
      return ('Finalizada', AppColors.neutral, Icons.check_circle_outline_rounded);
    }
    if (urgencia == 'ATRASADO' || diasRestantes < 0) {
      return ('Atrasada', AppColors.danger, Icons.error_outline_rounded);
    }
    if (diasRestantes == 0) {
      return ('Hoje', AppColors.dangerSoft, Icons.today_rounded);
    }
    if (diasRestantes == 1) {
      return ('Amanhã', AppColors.warningStrong, Icons.schedule_rounded);
    }
    return ('Em $diasRestantes dias', AppColors.subjectIndigo, Icons.event_available_rounded);
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
