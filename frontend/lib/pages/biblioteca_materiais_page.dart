import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/material_estudo.dart';
import '../providers/materiais_provider.dart';
import '../widgets/delete_confirm_dialog.dart';
import '../widgets/material_form_dialog.dart';

class BibliotecaMateriaisPage extends StatefulWidget {
  const BibliotecaMateriaisPage({super.key});

  @override
  State<BibliotecaMateriaisPage> createState() => _BibliotecaMateriaisPageState();
}

class _BibliotecaMateriaisPageState extends State<BibliotecaMateriaisPage> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MateriaisProvider>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm([MaterialEstudo? material]) async {
    final result = await showShadDialog<bool>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<MateriaisProvider>(),
        child: MaterialFormDialog(material: material),
      ),
    );
    if (result == true && mounted) {
      ShadToaster.of(context).show(
        ShadToast(
          description: Text(material == null ? 'Material adicionado.' : 'Material atualizado.'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(MaterialEstudo material) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmDialog(titulo: material.titulo),
    );
    if (confirmed == true && mounted) {
      final ok = await context.read<MateriaisProvider>().deleteMaterial(material.id);
      if (ok && mounted) {
        ShadToaster.of(context).show(
          const ShadToast(description: Text('Material removido.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadToaster(
      child: Scaffold(
        appBar: AppBar(
          title: _showSearch
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Buscar materiais...',
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => context.read<MateriaisProvider>().setSearch(v),
                )
              : const Text('Biblioteca de Materiais'),
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
          actions: [
            IconButton(
              icon: Icon(_showSearch ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                    context.read<MateriaisProvider>().setSearch('');
                  }
                });
              },
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterChips(),
            Expanded(child: _buildContent()),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filtros por disciplina
  // ---------------------------------------------------------------------------

  Widget _buildFilterChips() {
    final provider = context.watch<MateriaisProvider>();
    final disciplinas = provider.disciplinas;
    final selected = provider.selectedDisciplinaId;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _chip(null, 'Todos', selected),
          ...disciplinas.map((d) => _chip(d.id, d.nome, selected)),
        ],
      ),
    );
  }

  Widget _chip(String? id, String label, String? selected) {
    final isSelected = id == selected;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => context.read<MateriaisProvider>().setDisciplinaFilter(id),
        showCheckmark: false,
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        labelStyle: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Colors.grey[600],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Conteúdo principal
  // ---------------------------------------------------------------------------

  Widget _buildContent() {
    final provider = context.watch<MateriaisProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: () => context.read<MateriaisProvider>().init(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.materiais.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Nenhum material encontrado.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toque em "Adicionar" para cadastrar seu primeiro material.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: provider.materiais.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _MaterialCard(
        material: provider.materiais[i],
        onEdit: () => _openForm(provider.materiais[i]),
        onDelete: () => _confirmDelete(provider.materiais[i]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card de material
// ---------------------------------------------------------------------------

class _MaterialCard extends StatelessWidget {
  final MaterialEstudo material;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaterialCard({
    required this.material,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TipoIcon(tipo: material.tipo),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    material.disciplinaNome,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _TipoBadge(tipo: material.tipo),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        fmt.format(material.dataInsercao),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 20, color: Colors.grey[500]),
              onSelected: (action) {
                if (action == 'edit') onEdit();
                if (action == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 16),
                    SizedBox(width: 10),
                    Text('Editar'),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 16, color: Colors.red[600]),
                    const SizedBox(width: 10),
                    Text('Remover', style: TextStyle(color: Colors.red[600])),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares
// ---------------------------------------------------------------------------

class _TipoIcon extends StatelessWidget {
  final String tipo;
  const _TipoIcon({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (tipo) {
      'PDF' => (Icons.picture_as_pdf_outlined, Colors.red[600]!),
      'Link' => (Icons.link_rounded, Colors.blue[600]!),
      'Video' => (Icons.play_circle_outline_rounded, Colors.orange[700]!),
      'Resumo' => (Icons.edit_note_rounded, Colors.green[700]!),
      _ => (Icons.insert_drive_file_outlined, Colors.grey[600]!),
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }
}

class _TipoBadge extends StatelessWidget {
  final String tipo;
  const _TipoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final color = switch (tipo) {
      'PDF' => Colors.red[600]!,
      'Link' => Colors.blue[600]!,
      'Video' => Colors.orange[700]!,
      'Resumo' => Colors.green[700]!,
      _ => Colors.grey[600]!,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
