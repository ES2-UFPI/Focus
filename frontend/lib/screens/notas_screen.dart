import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/nota_estudo.dart';
import '../providers/notas_provider.dart';

/// Tela de Notas de Estudo: rail de disciplinas, lista com busca e painel de
/// detalhe/formulario. Persistencia via /api/materiais-estudo/ (sem backend novo).
class NotasScreen extends StatelessWidget {
  const NotasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotasProvider()..carregar(),
      child: const _NotasView(),
    );
  }
}

class _NotasView extends StatelessWidget {
  const _NotasView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotasProvider>();
    final isWide =
        MediaQuery.sizeOf(context).width >= AppSizes.desktopBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: provider.carregando && provider.todasNotas.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : isWide
                ? const _WideLayout()
                : const _NarrowLayout(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layout largo: rail de disciplinas | lista | painel principal
// ---------------------------------------------------------------------------

class _WideLayout extends StatelessWidget {
  const _WideLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        SizedBox(width: 190, child: _DisciplinasRail()),
        SizedBox(width: 320, child: _ListaNotas()),
        Expanded(child: _PainelPrincipal()),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Layout estreito: alterna entre lista e detalhe/formulario
// ---------------------------------------------------------------------------

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotasProvider>();
    final mostrandoLista = provider.modo == NotasModo.vazio;
    return mostrandoLista
        ? Column(
            children: const [
              Expanded(child: _ListaNotas()),
            ],
          )
        : Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    final p = context.read<NotasProvider>();
                    p.cancelarFormulario();
                    // Forca volta para a lista no mobile.
                    p.voltarParaLista();
                  },
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Notas'),
                ),
              ),
              const Expanded(child: _PainelPrincipal()),
            ],
          );
  }
}

// ---------------------------------------------------------------------------
// Rail de disciplinas
// ---------------------------------------------------------------------------

class _DisciplinasRail extends StatelessWidget {
  const _DisciplinasRail();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotasProvider>();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.borderSubtle)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 16),
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
                _chipDisciplina(context, provider, null, 'Todas'),
                for (final d in provider.disciplinas)
                  _chipDisciplina(context, provider, d.id, d.nome),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => context.read<NotasProvider>().novaNota(),
            icon: const Icon(Icons.add, size: 16),
            label: const Text(
              'Nova nota',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipDisciplina(
    BuildContext context,
    NotasProvider provider,
    String? id,
    String label,
  ) {
    final selecionada = provider.filtroDisciplinaId == id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => context.read<NotasProvider>().definirFiltroDisciplina(id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selecionada ? AppColors.textPrimary : AppColors.appBackground,
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
                    color: selecionada
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${provider.contagemPorDisciplina(id)}',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: selecionada
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

// ---------------------------------------------------------------------------
// Coluna da lista de notas
// ---------------------------------------------------------------------------

class _ListaNotas extends StatelessWidget {
  const _ListaNotas();

  @override
  Widget build(BuildContext context) {
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
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Notas de Estudo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (MediaQuery.sizeOf(context).width <
                        AppSizes.desktopBreakpoint)
                      IconButton(
                        tooltip: 'Nova nota',
                        onPressed: () =>
                            context.read<NotasProvider>().novaNota(),
                        icon: const Icon(Icons.add_circle,
                            color: AppColors.brandPrimary),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (v) =>
                      context.read<NotasProvider>().definirBusca(v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar nota...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.neutral),
                    prefixIcon: const Icon(Icons.search,
                        size: 17, color: AppColors.neutral),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (provider.erro != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Text(
                provider.erro!,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.danger),
              ),
            ),
          Expanded(
            child: notas.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhuma nota encontrada.',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.neutral),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                    itemCount: notas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 7),
                    itemBuilder: (context, i) =>
                        _CardNota(nota: notas[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CardNota extends StatelessWidget {
  final NotaEstudo nota;

  const _CardNota({required this.nota});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotasProvider>();
    final selecionada = provider.notaSelecionada?.id == nota.id &&
        provider.modo == NotasModo.detalhe;
    final tipo = nota.tipo;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.read<NotasProvider>().selecionarNota(nota.id!),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selecionada ? tipo.corSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selecionada ? tipo.cor : AppColors.borderSubtle,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _BadgeTipo(tipo: tipo),
                const Spacer(),
                Text(
                  nota.dataCurta,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.neutral),
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
              nota.disciplinaNome,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 5),
            Text(
              nota.snippet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.neutral),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTipo extends StatelessWidget {
  final TipoNota tipo;
  final double fontSize;

  const _BadgeTipo({required this.tipo, this.fontSize = 10.5});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tipo.corSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tipo.label.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: tipo.cor,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painel principal: detalhe, formulario ou vazio
// ---------------------------------------------------------------------------

class _PainelPrincipal extends StatelessWidget {
  const _PainelPrincipal();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotasProvider>();
    switch (provider.modo) {
      case NotasModo.formulario:
        return _FormularioNota(
          key: ValueKey(provider.emEdicao?.id ?? 'nova'),
          notaInicial: provider.emEdicao,
        );
      case NotasModo.detalhe:
        final nota = provider.notaSelecionada;
        if (nota == null) return const _EstadoVazio();
        return _DetalheNota(nota: nota);
      case NotasModo.vazio:
        return const _EstadoVazio();
    }
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined,
              size: 40, color: Color(0xFFD1D5DB)),
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

class _DetalheNota extends StatelessWidget {
  final NotaEstudo nota;

  const _DetalheNota({required this.nota});

  @override
  Widget build(BuildContext context) {
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
                      _BadgeTipo(tipo: nota.tipo, fontSize: 11),
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
                        '${nota.disciplinaNome} · Criada em ${nota.dataCurta}',
                        style: const TextStyle(
                            fontSize: 13.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  onPressed: () =>
                      context.read<NotasProvider>().editarNotaSelecionada(),
                  child: const Text('Editar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    backgroundColor: const Color(0xFFFDEAEA),
                    side: const BorderSide(color: Color(0xFFFBD5D5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  onPressed: () => _confirmarExclusao(context),
                  child: const Text('Excluir'),
                ),
              ],
            ),
            for (final def in kSecoesNota) ...[
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.borderSubtle),
              const SizedBox(height: 20),
              Text(
                def.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              if (nota.secao(def.key).isEmpty)
                const Text(
                  'Nada adicionado ainda.',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFFB0B0B8),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in nota.secao(def.key))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 8, right: 8),
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
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final provider = context.read<NotasProvider>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir nota'),
        content: Text('Excluir "${nota.titulo}"? Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await provider.excluirNotaSelecionada();
    }
  }
}

// ---------------------------------------------------------------------------
// Formulario de criacao/edicao
// ---------------------------------------------------------------------------

class _FormularioNota extends StatefulWidget {
  final NotaEstudo? notaInicial;

  const _FormularioNota({super.key, this.notaInicial});

  @override
  State<_FormularioNota> createState() => _FormularioNotaState();
}

class _FormularioNotaState extends State<_FormularioNota> {
  late final TextEditingController _tituloController;
  late final Map<String, TextEditingController> _secaoControllers;
  String? _disciplinaId;
  TipoNota _tipo = TipoNota.aula;

  @override
  void initState() {
    super.initState();
    final nota = widget.notaInicial;
    _tituloController = TextEditingController(text: nota?.titulo ?? '');
    _secaoControllers = {
      for (final def in kSecoesNota)
        def.key: TextEditingController(
          text: nota?.secao(def.key).join('\n') ?? '',
        ),
    };
    _disciplinaId = nota?.disciplinaId;
    _tipo = nota?.tipo ?? TipoNota.aula;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe a disciplina e o título da nota.'),
        ),
      );
      return;
    }
    final disciplina = provider.disciplinas
        .where((d) => d.id == _disciplinaId)
        .toList();
    List<String> paraLinhas(String texto) => texto
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final base = widget.notaInicial;
    final nota = NotaEstudo(
      id: base?.id,
      disciplinaId: _disciplinaId!,
      disciplinaNome:
          disciplina.isNotEmpty ? disciplina.first.nome : '',
      titulo: titulo,
      tipo: _tipo,
      data: base?.data ?? DateTime.now(),
      secoes: {
        for (final def in kSecoesNota)
          def.key: paraLinhas(_secaoControllers[def.key]!.text),
      },
    );
    await provider.salvar(nota);
  }

  InputDecoration _decoracao(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.neutral),
      isDense: true,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 11, horizontal: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _rotulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotasProvider>();
    final editando = widget.notaInicial != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editando ? 'Editar nota' : 'Nova Nota Acadêmica',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _rotulo('Disciplina'),
            DropdownButtonFormField<String>(
              initialValue: _disciplinaId,
              decoration: _decoracao('Selecione a disciplina'),
              items: [
                for (final d in provider.disciplinas)
                  DropdownMenuItem(
                    value: d.id,
                    child: Text(d.nome,
                        style: const TextStyle(fontSize: 14)),
                  ),
              ],
              onChanged: (v) => setState(() => _disciplinaId = v),
            ),
            const SizedBox(height: 16),
            _rotulo('Título da nota'),
            TextField(
              controller: _tituloController,
              style: const TextStyle(fontSize: 14),
              decoration:
                  _decoracao('Ex.: Aula sobre requisitos e backlog'),
            ),
            const SizedBox(height: 16),
            _rotulo('Tipo de nota'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in TipoNota.values)
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => setState(() => _tipo = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: _tipo == t ? t.cor : AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _tipo == t ? t.cor : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        t.label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _tipo == t
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            for (final def in kSecoesNota) ...[
              _rotulo(def.label),
              TextField(
                controller: _secaoControllers[def.key],
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                decoration: _decoracao(def.placeholder),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: provider.salvando ? null : _salvar,
                  child: Text(
                    provider.salvando ? 'Salvando...' : 'Salvar nota',
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () =>
                      context.read<NotasProvider>().cancelarFormulario(),
                  child: const Text('Cancelar',
                      style: TextStyle(fontSize: 14.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
