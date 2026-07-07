import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/app_theme.dart';
import '../models/disciplina.dart';
import '../models/nota.dart';
import '../providers/notas_provider.dart';
import '../widgets/delete_confirm_dialog.dart';

class NotasScreen extends StatelessWidget {
  const NotasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotasProvider(),
      child: const _NotasBody(),
    );
  }
}

class _NotasBody extends StatefulWidget {
  const _NotasBody();

  @override
  State<_NotasBody> createState() => _NotasBodyState();
}

class _NotasBodyState extends State<_NotasBody> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotasProvider>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmarExclusao(Nota nota) async {
    final provider = context.read<NotasProvider>();
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmDialog(titulo: nota.titulo),
    );
    if (confirmed == true && mounted) {
      final ok = await provider.excluir(nota.id);
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            description: Text(
              ok ? 'Nota removida.' : 'Não foi possível remover a nota.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).width >= AppSizes.desktopBreakpoint;
    return ShadToaster(
      child: Container(
        color: AppColors.appBackground,
        child: isWide ? _buildWide() : _buildNarrow(),
      ),
    );
  }

  Widget _buildWide() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 190, child: _DisciplinasRail()),
        SizedBox(width: 320, child: _buildLista()),
        Expanded(child: _buildPainel()),
      ],
    );
  }

  Widget _buildNarrow() {
    final provider = context.watch<NotasProvider>();
    if (provider.view == NotasView.vazio) {
      return Column(
        children: [
          Expanded(child: _buildLista()),
          Padding(
            padding: AppSpacing.screen,
            child: SizedBox(
              width: double.infinity,
              child: _NovaNotaButton(),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => context.read<NotasProvider>().voltarParaLista(),
            icon: const Icon(LucideIcons.arrowLeft, size: 16),
            label: const Text('Notas'),
          ),
        ),
        Expanded(child: _buildPainel()),
      ],
    );
  }

  Widget _buildLista() {
    final provider = context.watch<NotasProvider>();
    final notas = provider.notasFiltradas;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFC),
        border: Border(right: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notas de Estudo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.search,
                        size: 15,
                        color: AppColors.neutral,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: provider.setSearch,
                          decoration: const InputDecoration(
                            hintText: 'Buscar nota...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: AppColors.neutral,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 10),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? Center(
                        child: Text(
                          provider.error!,
                          style: const TextStyle(color: AppColors.neutral),
                        ),
                      )
                    : notas.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(30),
                              child: Text(
                                'Nenhuma nota encontrada.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.neutral,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                            itemCount: notas.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 7),
                            itemBuilder: (_, i) => _NotaCard(nota: notas[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPainel() {
    final provider = context.watch<NotasProvider>();
    switch (provider.view) {
      case NotasView.formulario:
        return _NotaForm(
          key: ValueKey(provider.editing?.id ?? 'nova'),
          editing: provider.editing,
        );
      case NotasView.detalhe:
        final nota = provider.selecionada;
        if (nota == null) return _buildVazio();
        return _NotaDetalhe(nota: nota, onDelete: () => _confirmarExclusao(nota));
      case NotasView.vazio:
        return _buildVazio();
    }
  }

  Widget _buildVazio() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.fileText, size: 40, color: Color(0xFFD1D5DB)),
          SizedBox(height: 10),
          Text(
            'Selecione uma nota para ler, ou crie uma nova.',
            style: TextStyle(fontSize: 14, color: AppColors.neutral),
          ),
        ],
      ),
    );
  }
}

class _NovaNotaButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShadButton(
      onPressed: () => context.read<NotasProvider>().abrirNova(),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.plus, size: 14),
          SizedBox(width: 7),
          Text('Nova nota'),
        ],
      ),
    );
  }
}

class _DisciplinasRail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotasProvider>();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.borderSubtle)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Text(
              'DISCIPLINAS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.neutral,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _chip(
                  context,
                  label: 'Todas',
                  count: provider.totalNotas,
                  selected: provider.filtroDisciplinaId == null,
                  onTap: () => provider.setFiltroDisciplina(null),
                ),
                for (final d in provider.disciplinas)
                  _chip(
                    context,
                    label: d.nome,
                    count: provider.contagemPorDisciplina(d.id),
                    selected: provider.filtroDisciplinaId == d.id,
                    onTap: () => provider.setFiltroDisciplina(d.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _NovaNotaButton(),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? AppColors.textPrimary : AppColors.appBackground,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.textInverted
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: selected
                      ? const Color(0xFFC7D2FE)
                      : AppColors.neutral,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotaCard extends StatelessWidget {
  final Nota nota;

  const _NotaCard({required this.nota});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotasProvider>();
    final selected = provider.selecionada?.id == nota.id &&
        provider.view == NotasView.detalhe;
    final cor = provider.corDaNota(nota);
    return InkWell(
      onTap: () => provider.selecionar(nota.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? cor.withValues(alpha: 0.08) : AppColors.surface,
          border: Border.all(
            color: selected ? cor : AppColors.borderSubtle,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: _DisciplinaBadge(nome: nota.disciplinaNome, cor: cor),
                ),
                const SizedBox(width: 6),
                Text(
                  nota.dataCurta,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              nota.titulo,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              nota.snippet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.neutral),
            ),
            if (nota.itensDe('duvidas').isNotEmpty) ...[
              const SizedBox(height: 7),
              _DuvidasBadge(count: nota.itensDe('duvidas').length),
            ],
          ],
        ),
      ),
    );
  }
}

/// Selo com a quantidade de itens em "Dúvidas pendentes" — permite varrer a
/// lista e ver de longe quais notas ainda precisam de revisão.
class _DuvidasBadge extends StatelessWidget {
  final int count;

  const _DuvidasBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.recommendationBackground,
        border: Border.all(color: AppColors.recommendationBorder),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.helpCircle,
            size: 11,
            color: AppColors.warningStrong,
          ),
          const SizedBox(width: 4),
          Text(
            count == 1 ? '1 dúvida pendente' : '$count dúvidas pendentes',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.warningStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisciplinaBadge extends StatelessWidget {
  final String nome;
  final Color cor;
  final bool large;

  const _DisciplinaBadge({
    required this.nome,
    required this.cor,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 8,
        vertical: large ? 3 : 2,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        nome.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: large ? 11 : 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: cor,
        ),
      ),
    );
  }
}

class _NotaDetalhe extends StatelessWidget {
  final Nota nota;
  final VoidCallback onDelete;

  const _NotaDetalhe({required this.nota, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotasProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DisciplinaBadge(
                        nome: nota.disciplinaNome,
                        cor: provider.corDaNota(nota),
                        large: true,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        nota.titulo,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Criada em ${nota.dataCurta}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                ShadButton.outline(
                  onPressed: provider.abrirEdicao,
                  child: const Text('Editar'),
                ),
                const SizedBox(width: 8),
                ShadButton.destructive(
                  onPressed: onDelete,
                  child: const Text('Excluir'),
                ),
              ],
            ),
            for (final sec in kNotaSecoes) _secao(sec, nota.itensDe(sec.key)),
          ],
        ),
      ),
    );
  }

  Widget _secao(NotaSecaoDef sec, List<String> itens) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sec.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (itens.isEmpty)
            const Text(
              'Nada adicionado ainda.',
              style: TextStyle(
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
                color: Color(0xFFB0B0B8),
              ),
            )
          else
            for (final item in itens)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 8, right: 9),
                      child: CircleAvatar(
                        radius: 2.5,
                        backgroundColor: AppColors.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
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

class _NotaForm extends StatefulWidget {
  final Nota? editing;

  const _NotaForm({super.key, this.editing});

  @override
  State<_NotaForm> createState() => _NotaFormState();
}

class _NotaFormState extends State<_NotaForm> {
  late final TextEditingController _tituloController;
  late final Map<String, TextEditingController> _secaoControllers;
  String? _disciplinaId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final n = widget.editing;
    _tituloController = TextEditingController(text: n?.titulo ?? '');
    _secaoControllers = {
      for (final sec in kNotaSecoes)
        sec.key: TextEditingController(text: n?.itensDe(sec.key).join('\n') ?? ''),
    };
    // Nova nota herda a disciplina filtrada no rail, se houver.
    _disciplinaId =
        n?.disciplinaId ?? context.read<NotasProvider>().filtroDisciplinaId;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    for (final c in _secaoControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    final provider = context.read<NotasProvider>();
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty || _disciplinaId == null) {
      ShadToaster.of(context).show(
        const ShadToast(
          description: Text('Informe a disciplina e o título da nota.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final secoes = {
      for (final sec in kNotaSecoes)
        sec.key: _secaoControllers[sec.key]!
            .text
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList(),
    };
    final ok = await provider.salvar(
      titulo: titulo,
      disciplinaId: _disciplinaId!,
      secoes: secoes,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ShadToaster.of(context).show(
      ShadToast(
        description: Text(ok
            ? (widget.editing == null ? 'Nota criada.' : 'Nota atualizada.')
            : 'Não foi possível salvar a nota.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotasProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editing == null ? 'Nova Nota Acadêmica' : 'Editar nota',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _label('Disciplina'),
            _buildDisciplinaDropdown(provider.disciplinas),
            const SizedBox(height: 16),
            _label('Título da nota'),
            TextField(
              controller: _tituloController,
              decoration: _inputDecoration('Ex.: Aula sobre requisitos e backlog'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _label('Data'),
            _buildDataField(),
            const SizedBox(height: 20),
            for (final sec in kNotaSecoes) ...[
              _label(sec.label),
              TextField(
                controller: _secaoControllers[sec.key],
                minLines: 3,
                maxLines: 6,
                decoration: _inputDecoration(sec.placeholder),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                ShadButton(
                  onPressed: _saving ? null : _salvar,
                  child: Text(_saving ? 'Salvando...' : 'Salvar nota'),
                ),
                const SizedBox(width: 10),
                ShadButton.outline(
                  onPressed: provider.cancelarFormulario,
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Campo somente leitura: data de criação da nota (hoje, ao criar uma nova).
  Widget _buildDataField() {
    final data = widget.editing?.dataInsercao ?? DateTime.now();
    final texto = '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.calendar,
            size: 15,
            color: AppColors.neutral,
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisciplinaDropdown(List<Disciplina> disciplinas) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _disciplinaId,
          isExpanded: true,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 13),
            child: Text(
              'Selecione a disciplina',
              style: TextStyle(fontSize: 14, color: AppColors.neutral),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          borderRadius: BorderRadius.circular(9),
          items: [
            for (final d in disciplinas)
              DropdownMenuItem(
                value: d.id,
                child: Text(d.nome, style: const TextStyle(fontSize: 14)),
              ),
          ],
          onChanged: (v) => setState(() => _disciplinaId = v),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.neutral),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.brandPrimary),
      ),
    );
  }
}
