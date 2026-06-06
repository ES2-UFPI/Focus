import 'package:flutter/material.dart';
import '../models/disciplina_model.dart';
import '../services/disciplina_service.dart';
import '../services/evento_service.dart';
import '../services/agenda_service.dart';
import '../widgets/criar_disciplina_dialog.dart';

class CriarEventoScreen extends StatefulWidget {
  const CriarEventoScreen({super.key});

  @override
  State<CriarEventoScreen> createState() => _CriarEventoScreenState();
}

class _CriarEventoScreenState extends State<CriarEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _disciplinaService = DisciplinaService();
  final _eventoService = EventoService();

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _dataController = TextEditingController();

  List<Disciplina> _disciplinas = [];
  String? _disciplinaSelecionadaId;
  String _tipoSelecionado = 'PROVA';
  DateTime? _dataSelecionada;

  bool _isLoadingDisciplinas = true;
  bool _isSaving = false;
  String? _errorMessage;

  final Map<String, String> _tiposEvento = {
    'PROVA': 'Prova 📝',
    'TRABALHO': 'Trabalho 📄',
    'SEMINARIO': 'Seminário 📌',
    'APRESENTACAO': 'Apresentação 🎤',
    'OUTRO': 'Outro 📋',
  };

  @override
  void initState() {
    super.initState();
    _carregarDisciplinas();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  Future<void> _carregarDisciplinas({String? selecionarId}) async {
    setState(() {
      _isLoadingDisciplinas = true;
      _errorMessage = null;
    });

    try {
      final lista = await _disciplinaService.getDisciplinas();
      setState(() {
        _disciplinas = lista;
        if (selecionarId != null && lista.any((d) => d.id == selecionarId)) {
          _disciplinaSelecionadaId = selecionarId;
        } else if (lista.isNotEmpty && _disciplinaSelecionadaId == null) {
          _disciplinaSelecionadaId = lista.first.id;
        }
        _isLoadingDisciplinas = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Falha ao carregar disciplinas. Verifique sua conexão.';
        _isLoadingDisciplinas = false;
      });
    }
  }

  Future<void> _criarDisciplinaInline() async {
    final novaDisciplina = await CriarDisciplinaDialog.show(context);
    if (!mounted) return;
    if (novaDisciplina != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disciplina "${novaDisciplina.nome}" criada!'),
          backgroundColor: Colors.green,
        ),
      );
      _carregarDisciplinas(selecionarId: novaDisciplina.id);
    }
  }

  Future<void> _selecionarData() async {
    final dataLimite = DateTime.now().add(const Duration(days: 365 * 2));
    final dataInicial = _dataSelecionada ?? DateTime.now();

    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: dataLimite,
    );

    if (selecionada != null) {
      setState(() {
        _dataSelecionada = selecionada;
        _dataController.text = "${selecionada.day.toString().padLeft(2, '0')}/"
            "${selecionada.month.toString().padLeft(2, '0')}/"
            "${selecionada.year}";
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_disciplinaSelecionadaId == null) {
      setState(() {
        _errorMessage = 'Por favor, selecione ou cadastre uma disciplina.';
      });
      return;
    }
    if (_dataSelecionada == null) {
      setState(() {
        _errorMessage = 'Por favor, selecione a data do evento.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _eventoService.criarEvento(
        disciplinaId: _disciplinaSelecionadaId!,
        titulo: _tituloController.text.trim(),
        tipo: _tipoSelecionado,
        dataEvento: _dataSelecionada!,
        descricao: _descricaoController.text.trim().isEmpty ? null : _descricaoController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evento criado com sucesso! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Retorna true para atualizar a lista
      }
    } on AgendaServiceException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocorreu um erro inesperado ao salvar o evento.';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Evento Acadêmico'),
        elevation: 0,
      ),
      body: _isLoadingDisciplinas
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Campo de Título
                    TextFormField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título do Evento *',
                        hintText: 'Ex: Prova Mensal de Álgebra',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Insira o título do evento';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Campo de Tipo de Evento
                    DropdownButtonFormField<String>(
                      initialValue: _tipoSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Evento *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _tiposEvento.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _tipoSelecionado = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Linha da Disciplina (Dropdown + Botão Novo)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _disciplinaSelecionadaId,
                            decoration: const InputDecoration(
                              labelText: 'Disciplina *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.book),
                            ),
                            items: _disciplinas.isEmpty
                                ? [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      enabled: false,
                                      child: Text('Nenhuma disciplina criada'),
                                    )
                                  ]
                                : _disciplinas.map((d) {
                                    return DropdownMenuItem<String>(
                                      value: d.id,
                                      child: Text(d.nome),
                                    );
                                  }).toList(),
                            validator: (val) {
                              if (val == null && _disciplinas.isNotEmpty) {
                                return 'Selecione uma disciplina';
                              }
                              if (_disciplinas.isEmpty) {
                                return 'Crie uma disciplina antes';
                              }
                              return null;
                            },
                            onChanged: (val) {
                              setState(() {
                                _disciplinaSelecionadaId = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 56,
                          child: FilledButton.tonal(
                            onPressed: _criarDisciplinaInline,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: const Icon(Icons.add),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Campo de Data
                    TextFormField(
                      controller: _dataController,
                      readOnly: true,
                      onTap: _selecionarData,
                      decoration: const InputDecoration(
                        labelText: 'Data do Evento *',
                        hintText: 'Selecione a data',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecione a data do evento';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Descrição
                    TextFormField(
                      controller: _descricaoController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descrição / Conteúdo (Opcional)',
                        hintText: 'Descreva os capítulos cobrados, observações, etc.',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 50),
                          child: Icon(Icons.description),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Botão Salvar
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _salvar,
                        child: _isSaving
                            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                            : const Text('SALVAR EVENTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
