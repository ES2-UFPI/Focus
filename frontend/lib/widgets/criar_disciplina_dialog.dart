import 'package:flutter/material.dart';
import '../models/disciplina_model.dart';
import '../services/disciplina_service.dart';
import '../services/agenda_service.dart';

class CriarDisciplinaDialog extends StatefulWidget {
  /// Quando informada, o diálogo edita a disciplina em vez de criar uma nova.
  final Disciplina? disciplinaExistente;

  const CriarDisciplinaDialog({super.key, this.disciplinaExistente});

  static Future<Disciplina?> show(
    BuildContext context, {
    Disciplina? disciplinaExistente,
  }) {
    return showDialog<Disciplina>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          CriarDisciplinaDialog(disciplinaExistente: disciplinaExistente),
    );
  }

  @override
  State<CriarDisciplinaDialog> createState() => _CriarDisciplinaDialogState();
}

class _CriarDisciplinaDialogState extends State<CriarDisciplinaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _disciplinaService = DisciplinaService();

  final _nomeController = TextEditingController();
  final _codigoController = TextEditingController();
  final _descricaoController = TextEditingController();

  String _corSelecionada = '#2196F3'; // Azul padrão
  bool _isSaving = false;
  String? _errorMessage;

  bool get _editando => widget.disciplinaExistente != null;

  @override
  void initState() {
    super.initState();
    final d = widget.disciplinaExistente;
    if (d != null) {
      _nomeController.text = d.nome;
      _codigoController.text = d.codigo ?? '';
      _descricaoController.text = d.descricao ?? '';
      _corSelecionada = d.cor;
    }
  }

  final List<Map<String, String>> _paletaCores = [
    {'nome': 'Azul', 'hex': '#2196F3'},
    {'nome': 'Verde', 'hex': '#4CAF50'},
    {'nome': 'Vermelho', 'hex': '#F44336'},
    {'nome': 'Laranja', 'hex': '#FF9800'},
    {'nome': 'Roxo', 'hex': '#9C27B0'},
    {'nome': 'Rosa', 'hex': '#E91E63'},
    {'nome': 'Ciano', 'hex': '#00BCD4'},
    {'nome': 'Cinza', 'hex': '#9E9E9E'},
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _codigoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final nome = _nomeController.text.trim();
      final codigo =
          _codigoController.text.trim().isEmpty ? null : _codigoController.text.trim();
      final descricao =
          _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim();

      final disciplina = _editando
          ? await _disciplinaService.atualizarDisciplina(
              id: widget.disciplinaExistente!.id,
              nome: nome,
              codigo: codigo,
              descricao: descricao,
              cor: _corSelecionada,
            )
          : await _disciplinaService.criarDisciplina(
              nome: nome,
              codigo: codigo,
              descricao: descricao,
              cor: _corSelecionada,
            );

      if (mounted) {
        Navigator.of(context).pop(disciplina);
      }
    } on AgendaServiceException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocorreu um erro inesperado ao salvar a disciplina.';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editando ? 'Editar Disciplina' : 'Nova Disciplina'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Disciplina *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código (ex: MAT101)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Text(
                'Cor da Disciplina:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _paletaCores.map((cor) {
                  final hex = cor['hex']!;
                  final colorVal = Color(int.parse(hex.replaceFirst('#', 'FF'), radix: 16));
                  final isSelecionada = _corSelecionada == hex;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _corSelecionada = hex;
                      });
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colorVal,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelecionada ? Colors.black : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isSelecionada
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _salvar,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_editando ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }
}
