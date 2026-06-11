import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/disciplina.dart';
import '../models/material_estudo.dart';
import '../providers/materiais_provider.dart';

class MaterialFormDialog extends StatefulWidget {
  final MaterialEstudo? material;

  const MaterialFormDialog({super.key, this.material});

  @override
  State<MaterialFormDialog> createState() => _MaterialFormDialogState();
}

class _MaterialFormDialogState extends State<MaterialFormDialog> {
  final _formKey = GlobalKey<ShadFormState>();
  late String _titulo;
  late String _tipo;
  late String? _disciplinaId;
  late String _url;
  late String _descricao;
  bool _loading = false;

  static const _tipos = ['PDF', 'Resumo', 'Link', 'Video', 'Outro'];

  @override
  void initState() {
    super.initState();
    _titulo = widget.material?.titulo ?? '';
    _tipo = widget.material?.tipo ?? 'PDF';
    _disciplinaId = widget.material?.disciplinaId;
    _url = widget.material?.url ?? '';
    _descricao = widget.material?.descricao ?? '';
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.saveAndValidate() != true) return;
    if (_disciplinaId == null) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(description: Text('Selecione uma disciplina.')),
      );
      return;
    }

    setState(() => _loading = true);
    final provider = context.read<MateriaisProvider>();
    final data = {
      'titulo': _titulo,
      'tipo': _tipo,
      'disciplina': _disciplinaId,
      if (_url.isNotEmpty) 'url': _url,
      if (_descricao.isNotEmpty) 'descricao': _descricao,
    };

    bool ok;
    if (widget.material == null) {
      ok = await provider.addMaterial(data);
    } else {
      ok = await provider.updateMaterial(widget.material!.id, data);
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      ShadToaster.of(context).show(
        const ShadToast.destructive(description: Text('Ocorreu um erro. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final disciplinas = context.watch<MateriaisProvider>().disciplinas;
    final isEdit = widget.material != null;

    return ShadDialog(
      title: Text(isEdit ? 'Editar material' : 'Adicionar material'),
      description: Text(isEdit ? 'Edite os dados do material.' : 'Preencha os dados do novo material.'),
      actions: [
        ShadButton.outline(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ShadButton(
          onPressed: _loading ? null : _submit,
          leading: _loading
              ? const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : null,
          child: Text(isEdit ? 'Salvar' : 'Adicionar'),
        ),
      ],
      child: SizedBox(
        width: 440,
        child: ShadForm(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShadInputFormField(
                  id: 'titulo',
                  label: const Text('Título'),
                  placeholder: const Text('Nome do material'),
                  initialValue: _titulo,
                  validator: (v) => v.isEmpty ? 'Informe o título.' : null,
                  onChanged: (v) => _titulo = v,
                ),
                const SizedBox(height: 12),
                _buildSelectTipo(),
                const SizedBox(height: 12),
                _buildSelectDisciplina(disciplinas),
                const SizedBox(height: 12),
                ShadInputFormField(
                  id: 'url',
                  label: const Text('URL / Link'),
                  placeholder: const Text('https://...'),
                  initialValue: _url,
                  onChanged: (v) => _url = v,
                ),
                const SizedBox(height: 12),
                ShadInputFormField(
                  id: 'descricao',
                  label: const Text('Descrição'),
                  placeholder: const Text('Descrição opcional'),
                  initialValue: _descricao,
                  onChanged: (v) => _descricao = v,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectTipo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text('Tipo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        ShadSelect<String>(
          placeholder: const Text('Selecione o tipo'),
          initialValue: _tipo,
          onChanged: (v) => setState(() => _tipo = v ?? 'PDF'),
          options: _tipos.map((t) => ShadOption(value: t, child: Text(t))).toList(),
          selectedOptionBuilder: (context, value) => Text(value),
        ),
      ],
    );
  }

  Widget _buildSelectDisciplina(List<Disciplina> disciplinas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text('Disciplina', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
        ShadSelect<String>(
          placeholder: const Text('Selecione a disciplina'),
          initialValue: _disciplinaId,
          onChanged: (v) => setState(() => _disciplinaId = v),
          options: disciplinas
              .map((d) => ShadOption(value: d.id, child: Text(d.nome)))
              .toList(),
          selectedOptionBuilder: (context, value) {
            final d = disciplinas.where((d) => d.id == value).firstOrNull;
            return Text(d?.nome ?? value);
          },
        ),
      ],
    );
  }
}
