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
        backgroundColor: const Color(0xFFF8F9FC),
        body: Row(
          children: [
            _buildCategoryPanel(),
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPanel() {
    final provider = context.watch<MateriaisProvider>();
    final disciplinas = provider.disciplinas;
    final selected = provider.selectedDisciplinaId;

    return Container(
      width: 200,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Text(
              'Categorias',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
          ),
          _categoryItem(null, 'Todos', selected),
          ...disciplinas.map((d) => _categoryItem(d.id, d.nome, selected)),
        ],
      ),
    );
  }

  Widget _categoryItem(String? id, String label, String? selected) {
    final isSelected = id == selected;
    return GestureDetector(
      onTap: () => context.read<MateriaisProvider>().setDisciplinaFilter(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            if (isSelected)
              Container(
                width: 3,
                height: 14,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366f1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFF6366f1) : Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final provider = context.watch<MateriaisProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(provider),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? Center(child: Text(provider.error!, style: const TextStyle(color: Colors.red)))
                    : provider.materiais.isEmpty
                        ? _buildEmpty()
                        : _buildTable(provider.materiais),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(MateriaisProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      color: const Color(0xFFF8F9FC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Biblioteca de Materiais',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ShadInput(
                  controller: _searchController,
                  placeholder: const Text('Buscar materiais...'),
                  leading: const Icon(LucideIcons.search, size: 16),
                  onChanged: (v) => provider.setSearch(v),
                ),
              ),
              const SizedBox(width: 12),
              ShadButton(
                onPressed: () => _openForm(),
                leading: const Icon(LucideIcons.plus, size: 16),
                child: const Text('Adicionar material'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.folderOpen, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Nenhum material encontrado.',
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
          const SizedBox(height: 8),
          ShadButton.outline(
            onPressed: () => _openForm(),
            child: const Text('Adicionar primeiro material'),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<MaterialEstudo> materiais) {
    final fmt = DateFormat('dd/MM/yyyy');
    return ShadCard(
      padding: EdgeInsets.zero,
      child: ShadTable.list(
        columnSpanExtent: (i) {
          switch (i) {
            case 0: return const FixedTableSpanExtent(240);
            case 1: return const FixedTableSpanExtent(150);
            case 2: return const FixedTableSpanExtent(100);
            case 3: return const FixedTableSpanExtent(100);
            default: return const FixedTableSpanExtent(50);
          }
        },
        header: const [
          ShadTableCell.header(child: Text('Material')),
          ShadTableCell.header(child: Text('Disciplina')),
          ShadTableCell.header(child: Text('Tipo')),
          ShadTableCell.header(child: Text('Data')),
          ShadTableCell.header(child: Text('')),
        ],
        children: materiais.map((m) => [
          ShadTableCell(
            child: Row(
              children: [
                _tipoIcon(m.tipo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    m.titulo,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          ShadTableCell(
            child: Text(m.disciplinaNome, overflow: TextOverflow.ellipsis),
          ),
          ShadTableCell(child: _tipoBadge(m.tipo)),
          ShadTableCell(
            child: Text(
              fmt.format(m.dataInsercao),
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          ShadTableCell(child: _rowMenu(m)),
        ]).toList(),
      ),
    );
  }

  Widget _tipoIcon(String tipo) {
    IconData icon;
    Color color;
    switch (tipo) {
      case 'PDF':   icon = LucideIcons.fileText; color = Colors.red;
      case 'Link':  icon = LucideIcons.link;     color = Colors.blue;
      case 'Video': icon = LucideIcons.video;    color = Colors.orange;
      case 'Resumo': icon = LucideIcons.penLine; color = Colors.green;
      default:      icon = LucideIcons.file;     color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _tipoBadge(String tipo) {
    return ShadBadge.secondary(
      child: Text(tipo, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _rowMenu(MaterialEstudo m) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
      onSelected: (action) {
        if (action == 'edit') _openForm(m);
        if (action == 'delete') _confirmDelete(m);
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16),
              SizedBox(width: 8),
              Text('Editar'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16, color: Colors.red[600]),
              const SizedBox(width: 8),
              Text('Remover', style: TextStyle(color: Colors.red[600])),
            ],
          ),
        ),
      ],
    );
  }
}
