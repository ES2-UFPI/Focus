import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/disciplina_model.dart';
import '../services/disciplina_service.dart';
import '../widgets/criar_disciplina_dialog.dart';

/// Aba dedicada ao cadastro e gerenciamento de disciplinas. As disciplinas
/// criadas aqui ficam disponíveis em todo o app (Pomodoro, Eventos Acadêmicos,
/// etc.), pois todas as telas leem do mesmo endpoint `/api/disciplinas/`.
class DisciplinasScreen extends StatefulWidget {
  /// Injetável nos testes.
  final DisciplinaService? disciplinaService;

  const DisciplinasScreen({super.key, this.disciplinaService});

  @override
  State<DisciplinasScreen> createState() => _DisciplinasScreenState();
}

class _DisciplinasScreenState extends State<DisciplinasScreen> {
  static const double _wideBreakpoint = 900;

  late final DisciplinaService _service =
      widget.disciplinaService ?? DisciplinaService();

  List<Disciplina> _disciplinas = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final lista = await _service.getDisciplinas();
      if (!mounted) return;
      setState(() {
        _disciplinas = lista;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível carregar as disciplinas.';
        _isLoading = false;
      });
    }
  }

  Future<void> _abrirFormulario({Disciplina? existente}) async {
    final resultado = await CriarDisciplinaDialog.show(
      context,
      disciplinaExistente: existente,
    );
    if (resultado != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existente != null
                ? 'Disciplina "${resultado.nome}" atualizada.'
                : 'Disciplina "${resultado.nome}" criada.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      await _carregar();
    }
  }

  Future<void> _confirmarExclusao(Disciplina d) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir disciplina'),
        content: Text(
          'Tem certeza que deseja excluir "${d.nome}"? Eventos e sessões '
          'vinculados a ela podem ser afetados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await _service.excluirDisciplina(d.id);
      if (!mounted) return;
      setState(() => _disciplinas.removeWhere((e) => e.id == d.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disciplina "${d.nome}" removida.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a disciplina.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        tooltip: 'Nova disciplina',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _wideBreakpoint;
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
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_errorMessage != null)
                  _ErrorState(message: _errorMessage!, onRetry: _carregar)
                else if (_disciplinas.isEmpty)
                  const _EmptyState()
                else
                  _buildGrid(wide),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Disciplinas',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Cadastre suas matérias uma vez e use em eventos, Pomodoro e consistência.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      ],
    );
  }

  Widget _buildGrid(bool wide) {
    if (wide) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final d in _disciplinas)
            SizedBox(width: 360, child: _DisciplinaCard(
              disciplina: d,
              onEdit: () => _abrirFormulario(existente: d),
              onDelete: () => _confirmarExclusao(d),
            )),
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < _disciplinas.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _DisciplinaCard(
            disciplina: _disciplinas[i],
            onEdit: () => _abrirFormulario(existente: _disciplinas[i]),
            onDelete: () => _confirmarExclusao(_disciplinas[i]),
          ),
        ],
      ],
    );
  }
}

Color _corFromHex(String hex) {
  final value = hex.replaceFirst('#', '');
  final full = value.length == 6 ? 'FF$value' : value;
  return Color(int.tryParse(full, radix: 16) ?? 0xFF2196F3);
}

class _DisciplinaCard extends StatelessWidget {
  final Disciplina disciplina;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DisciplinaCard({
    required this.disciplina,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cor = _corFromHex(disciplina.cor);
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
            border: Border(left: BorderSide(color: cor, width: 4)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.menu_book_rounded, color: cor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            disciplina.nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (disciplina.codigo != null &&
                            disciplina.codigo!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: cor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              disciplina.codigo!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: cor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (disciplina.descricao != null &&
                        disciplina.descricao!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        disciplina.descricao!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined,
                    size: 20, color: AppColors.textMuted),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Excluir',
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 20, color: Color(0xFFE53935)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma disciplina cadastrada.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Toque no botão + para cadastrar sua primeira matéria.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
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
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
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
