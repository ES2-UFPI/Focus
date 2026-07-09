import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/agenda_model.dart';
import '../models/disciplina_model.dart';
import '../providers/app_shell_provider.dart';
import '../services/disciplina_service.dart';
import '../services/sessao_estudo_service.dart';
import '../services/agenda_service.dart';
import '../widgets/criar_disciplina_dialog.dart';

class CriarSessaoScreen extends StatefulWidget {
  final AgendaItem? sessaoExistente;
  final String? disciplinaIdInicial;
  final String? horarioSugerido;

  const CriarSessaoScreen({
    super.key,
    this.sessaoExistente,
    this.disciplinaIdInicial,
    this.horarioSugerido,
  });

  @override
  State<CriarSessaoScreen> createState() => _CriarSessaoScreenState();
}

class _CriarSessaoScreenState extends State<CriarSessaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _disciplinaService = DisciplinaService();
  final _sessaoService = SessaoEstudoService();

  final _descricaoController = TextEditingController();
  final _dataController = TextEditingController();
  final _horaInicioController = TextEditingController();
  final _horaFimController = TextEditingController();

  List<Disciplina> _disciplinas = [];
  String? _disciplinaSelecionadaId;

  DateTime? _dataSelecionada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;

  bool _isLoadingDisciplinas = true;
  bool _isSaving = false;
  String? _errorMessage;

  String _statusSelecionado = 'AGENDADO';
  String? _tipoAtividadeSelecionado;
  final _duracaoController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    if (widget.sessaoExistente != null) {
      final se = widget.sessaoExistente!;
      _descricaoController.text = se.descricao ?? '';
      _disciplinaSelecionadaId = se.disciplinaId;

      _statusSelecionado = se.status ?? 'AGENDADO';
      _tipoAtividadeSelecionado = se.tipoAtividade;
      _duracaoController.text = (se.duracaoRealizada ?? 0).toString();

      if (se.inicio != null) {
        _dataSelecionada = se.inicio;
        _dataController.text =
            "${se.inicio!.day.toString().padLeft(2, '0')}/"
            "${se.inicio!.month.toString().padLeft(2, '0')}/"
            "${se.inicio!.year}";
        _horaInicio = TimeOfDay.fromDateTime(se.inicio!);
        _horaInicioController.text =
            "${_horaInicio!.hour.toString().padLeft(2, '0')}:${_horaInicio!.minute.toString().padLeft(2, '0')}";
      }

      if (se.fim != null) {
        _horaFim = TimeOfDay.fromDateTime(se.fim!);
        _horaFimController.text =
            "${_horaFim!.hour.toString().padLeft(2, '0')}:${_horaFim!.minute.toString().padLeft(2, '0')}";
      }
    } else {
      _disciplinaSelecionadaId = widget.disciplinaIdInicial;
      _horaInicio = _horaInicialSugerida(widget.horarioSugerido);
      if (_horaInicio != null) {
        _horaInicioController.text =
            "${_horaInicio!.hour.toString().padLeft(2, '0')}:"
            "${_horaInicio!.minute.toString().padLeft(2, '0')}";
      }
    }
    _carregarDisciplinas();
  }

  TimeOfDay? _horaInicialSugerida(String? periodo) {
    switch (periodo?.toLowerCase()) {
      case 'manha':
        return const TimeOfDay(hour: 8, minute: 0);
      case 'tarde':
        return const TimeOfDay(hour: 14, minute: 0);
      case 'noite':
        return const TimeOfDay(hour: 20, minute: 0);
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _dataController.dispose();
    _horaInicioController.dispose();
    _horaFimController.dispose();
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
        } else if (lista.isNotEmpty &&
            !lista.any((d) => d.id == _disciplinaSelecionadaId)) {
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
    final novaDisciplina = await showDialog<Disciplina>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Theme(
        data: _lightFormTheme(context),
        child: const CriarDisciplinaDialog(),
      ),
    );
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

  void _notificarPomodoroSobreSessaoAlterada() {
    try {
      context.read<AppShellProvider>().notifyPomodoroDataChanged();
    } on ProviderNotFoundException {
      // A tela tambem pode ser usada isolada em testes.
    }
  }

  Future<void> _selecionarData() async {
    final dataInicial = _dataSelecionada ?? DateTime.now();

    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: _lightFormTheme(context),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (selecionada != null) {
      setState(() {
        _dataSelecionada = selecionada;
        _dataController.text =
            "${selecionada.day.toString().padLeft(2, '0')}/"
            "${selecionada.month.toString().padLeft(2, '0')}/"
            "${selecionada.year}";
      });
    }
  }

  Future<void> _selecionarHoraInicio() async {
    final horaInicial = _horaInicio ?? TimeOfDay.now();

    final TimeOfDay? selecionada = await showTimePicker(
      context: context,
      initialTime: horaInicial,
      builder: (context, child) => Theme(
        data: _lightFormTheme(context),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (selecionada != null) {
      setState(() {
        _horaInicio = selecionada;
        _horaInicioController.text =
            "${selecionada.hour.toString().padLeft(2, '0')}:${selecionada.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selecionarHoraFim() async {
    final horaInicial = _horaFim ?? TimeOfDay.now();

    final TimeOfDay? selecionada = await showTimePicker(
      context: context,
      initialTime: horaInicial,
      builder: (context, child) => Theme(
        data: _lightFormTheme(context),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (selecionada != null) {
      setState(() {
        _horaFim = selecionada;
        _horaFimController.text =
            "${selecionada.hour.toString().padLeft(2, '0')}:${selecionada.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_disciplinaSelecionadaId == null) {
      setState(() => _errorMessage = 'Selecione uma disciplina.');
      return;
    }
    if (_dataSelecionada == null || _horaInicio == null || _horaFim == null) {
      setState(
        () => _errorMessage =
            'Data e horários de início e término são obrigatórios.',
      );
      return;
    }

    // Montando objetos DateTime completos para validação local e para o envio correto ao service
    final inicio = DateTime(
      _dataSelecionada!.year,
      _dataSelecionada!.month,
      _dataSelecionada!.day,
      _horaInicio!.hour,
      _horaInicio!.minute,
    );

    final fim = DateTime(
      _dataSelecionada!.year,
      _dataSelecionada!.month,
      _dataSelecionada!.day,
      _horaFim!.hour,
      _horaFim!.minute,
    );

    if (fim.isBefore(inicio) || fim.isAtSameMomentAs(inicio)) {
      setState(() {
        _errorMessage =
            'A hora de término deve ser posterior à hora de início.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final String? descricaoVal = _descricaoController.text.trim().isEmpty
          ? null
          : _descricaoController.text.trim();

      // Captura os minutos digitados na tela de forma segura
      final int minutosEstudados = int.tryParse(_duracaoController.text) ?? 0;

      if (widget.sessaoExistente != null) {
        // 🔥 ENVIANDO O DATETIME NOVAMENTE (O service vai injetar o fuso horário correto automaticamente)
        await _sessaoService.editarSessao(
          sessaoId: widget.sessaoExistente!.id,
          disciplinaId: _disciplinaSelecionadaId!,
          inicio: inicio, // 🌟 Alterado para passar o objeto DateTime completo
          fim: fim, // 🌟 Alterado para passar o objeto DateTime completo
          descricao: descricaoVal,
          status: _statusSelecionado,
          duracaoRealizada: minutosEstudados,
          energiaInicial: widget.sessaoExistente!.energiaInicial,
          interrupcoes: widget.sessaoExistente!.interrupcoes,
          tipoAtividade: _tipoAtividadeSelecionado,
        );
      } else {
        // 🚀 ENVIANDO O DATETIME NOVAMENTE (O service vai injetar o fuso horário correto automaticamente)
        await _sessaoService.criarSessao(
          disciplinaId: _disciplinaSelecionadaId!,
          inicio: inicio, // 🌟 Alterado para passar o objeto DateTime completo
          fim: fim, // 🌟 Alterado para passar o objeto DateTime completo
          descricao: descricaoVal,
          status: _statusSelecionado,
          duracaoRealizada: minutosEstudados,
          energiaInicial: null,
          interrupcoes: 0,
          tipoAtividade: _tipoAtividadeSelecionado,
        );
      }

      if (mounted) {
        _notificarPomodoroSobreSessaoAlterada();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.sessaoExistente != null
                  ? 'Sessão de estudo atualizada com sucesso! 📚'
                  : 'Sessão de estudo agendada com sucesso! 📚',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on AgendaServiceException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocorreu um erro inesperado ao agendar a sessão.';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.sessaoExistente != null
        ? 'Editar Sessão de Estudo'
        : 'Nova Sessão de Estudo';

    return Theme(
      data: _lightFormTheme(context),
      child: Scaffold(
        backgroundColor: AppColors.appBackground,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 760
                  ? AppSpacing.lg
                  : AppSpacing.xxxl;
              final verticalPadding = constraints.maxHeight < 760
                  ? AppSpacing.lg
                  : AppSpacing.xxxl;
              final maxCardHeight = constraints.maxHeight < 760
                  ? constraints.maxHeight - (verticalPadding * 2)
                  : 700.0;

              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 720,
                      maxHeight: maxCardHeight,
                    ),
                    child: DecoratedBox(
                      decoration: AppDecorations.card(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: Column(
                          children: [
                            _SessaoFormHeader(title: title),
                            const Divider(
                              height: 1,
                              color: AppColors.borderSubtle,
                            ),
                            Expanded(
                              child: _isLoadingDisciplinas
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : SingleChildScrollView(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.xl,
                                      ),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            if (_errorMessage != null) ...[
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.red.shade200,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.error_outline,
                                                      color:
                                                          Colors.red.shade700,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        _errorMessage!,
                                                        style: TextStyle(
                                                          color: Colors
                                                              .red
                                                              .shade900,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                            ],

                                            // Linha da Disciplina (Dropdown + Botão Novo)
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: DropdownButtonFormField<String>(
                                                    initialValue:
                                                        _disciplinaSelecionadaId,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText:
                                                              'Disciplina *',
                                                          border:
                                                              OutlineInputBorder(),
                                                          prefixIcon: Icon(
                                                            Icons.book,
                                                          ),
                                                        ),
                                                    items: _disciplinas.isEmpty
                                                        ? [
                                                            const DropdownMenuItem<
                                                              String
                                                            >(
                                                              value: null,
                                                              enabled: false,
                                                              child: Text(
                                                                'Nenhuma disciplina criada',
                                                              ),
                                                            ),
                                                          ]
                                                        : _disciplinas.map((d) {
                                                            return DropdownMenuItem<
                                                              String
                                                            >(
                                                              value: d.id,
                                                              child: Text(
                                                                d.nome,
                                                              ),
                                                            );
                                                          }).toList(),
                                                    validator: (val) {
                                                      if (val == null &&
                                                          _disciplinas
                                                              .isNotEmpty) {
                                                        return 'Selecione uma disciplina';
                                                      }
                                                      if (_disciplinas
                                                          .isEmpty) {
                                                        return 'Crie uma disciplina antes';
                                                      }
                                                      return null;
                                                    },
                                                    onChanged: (val) {
                                                      setState(() {
                                                        _disciplinaSelecionadaId =
                                                            val;
                                                      });
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                SizedBox(
                                                  height: 56,
                                                  child: FilledButton.tonal(
                                                    onPressed:
                                                        _criarDisciplinaInline,
                                                    style: FilledButton.styleFrom(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.add,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),

                                            InputDecorator(
                                              decoration: const InputDecoration(
                                                labelText:
                                                    'Tipo de atividade (opcional)',
                                                helperText:
                                                    'Um toque basta; toque novamente para remover.',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.category_outlined,
                                                ),
                                              ),
                                              child: Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children:
                                                    const [
                                                      (
                                                        'LEITURA',
                                                        'Leitura',
                                                        Icons
                                                            .menu_book_outlined,
                                                      ),
                                                      (
                                                        'EXERCICIO',
                                                        'Exercício',
                                                        Icons
                                                            .edit_note_outlined,
                                                      ),
                                                      (
                                                        'REVISAO',
                                                        'Revisão',
                                                        Icons.replay_outlined,
                                                      ),
                                                    ].map((item) {
                                                      final (
                                                        value,
                                                        label,
                                                        icon,
                                                      ) = item;
                                                      return ChoiceChip(
                                                        key: ValueKey(
                                                          'tipo-atividade-$value',
                                                        ),
                                                        selected:
                                                            _tipoAtividadeSelecionado ==
                                                            value,
                                                        avatar: Icon(
                                                          icon,
                                                          size: 18,
                                                        ),
                                                        label: Text(label),
                                                        onSelected: (selected) {
                                                          setState(() {
                                                            _tipoAtividadeSelecionado =
                                                                selected
                                                                ? value
                                                                : null;
                                                          });
                                                        },
                                                      );
                                                    }).toList(),
                                              ),
                                            ),
                                            const SizedBox(height: 20),

                                            // 🌟 NOVO CAMPO: Seletor Dinâmico de Status
                                            DropdownButtonFormField<String>(
                                              initialValue:
                                                  _statusSelecionado, // Variável que criamos no estado da tela
                                              decoration: const InputDecoration(
                                                labelText: 'Status da Sessão *',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(Icons.rule),
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 'AGENDADO',
                                                  child: Text(
                                                    'Agendado (Planejar futuro)',
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'CONCLUIDO',
                                                  child: Text(
                                                    'Concluído (Computar na Consistência)',
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'CANCELADO',
                                                  child: Text('Cancelado'),
                                                ),
                                              ],
                                              onChanged: (val) {
                                                setState(() {
                                                  _statusSelecionado =
                                                      val ?? 'AGENDADO';
                                                });
                                              },
                                            ),
                                            const SizedBox(height: 20),

                                            // 🌟 NOVO CAMPO CONDICIONAL: Tempo Realizado em Minutos
                                            // O operador 'if' do Dart renderiza o widget na árvore apenas sob essa condição
                                            if (_statusSelecionado ==
                                                'CONCLUIDO') ...[
                                              TextFormField(
                                                controller:
                                                    _duracaoController, // Controlador numérico
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: const InputDecoration(
                                                  labelText:
                                                      'Tempo Real de Estudo (em minutos) *',
                                                  hintText:
                                                      'Ex: 90 para 1h30min de foco',
                                                  border: OutlineInputBorder(),
                                                  prefixIcon: Icon(Icons.timer),
                                                ),
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Informe a duração real da sessão';
                                                  }
                                                  final minutos = int.tryParse(
                                                    value,
                                                  );
                                                  if (minutos == null ||
                                                      minutos <= 0) {
                                                    return 'Insira um valor numérico válido maior que zero';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 20),
                                            ],

                                            // Campo de Data
                                            TextFormField(
                                              controller: _dataController,
                                              readOnly: true,
                                              onTap: _selecionarData,
                                              decoration: const InputDecoration(
                                                labelText: 'Data da Sessão *',
                                                hintText: 'Selecione a data',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.calendar_today,
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Selecione a data';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 20),

                                            // Horário de Início
                                            TextFormField(
                                              controller: _horaInicioController,
                                              readOnly: true,
                                              onTap: _selecionarHoraInicio,
                                              decoration: const InputDecoration(
                                                labelText: 'Hora de Início *',
                                                hintText: '00:00',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.access_time,
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Selecione a hora de início';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 20),

                                            // Horário de Término
                                            TextFormField(
                                              controller: _horaFimController,
                                              readOnly: true,
                                              onTap: _selecionarHoraFim,
                                              decoration: const InputDecoration(
                                                labelText: 'Hora de Término *',
                                                hintText: '00:00',
                                                border: OutlineInputBorder(),
                                                prefixIcon: Icon(
                                                  Icons.access_time_filled,
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Selecione a hora de término';
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
                                                labelText:
                                                    'Descrição / Tópicos de Foco (Opcional)',
                                                hintText:
                                                    'Ex: revisar árvores binárias, praticar SQL.',
                                                border: OutlineInputBorder(),
                                                alignLabelWithHint: true,
                                                prefixIcon: Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: 50,
                                                  ),
                                                  child: Icon(
                                                    Icons.description,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 30),

                                            // Botão Salvar
                                            SizedBox(
                                              height: 50,
                                              child: FilledButton(
                                                onPressed: _isSaving
                                                    ? null
                                                    : _salvar,
                                                child: _isSaving
                                                    ? const CircularProgressIndicator(
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.white),
                                                      )
                                                    : Text(
                                                        widget.sessaoExistente !=
                                                                null
                                                            ? 'SALVAR ALTERAÇÕES'
                                                            : 'SALVAR SESSÃO',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

ThemeData _lightFormTheme(BuildContext context) {
  final base = Theme.of(context);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brandPrimary,
    brightness: Brightness.light,
  );

  OutlineInputBorder fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return base.copyWith(
    brightness: Brightness.light,
    colorScheme: colorScheme.copyWith(
      primary: AppColors.brandPrimary,
      onPrimary: AppColors.textInverted,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.appBackground,
    canvasColor: AppColors.surface,
    cardColor: AppColors.surface,
    dividerColor: AppColors.borderSubtle,
    iconTheme: const IconThemeData(color: AppColors.textSecondary),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: AppTypography.caption.copyWith(
        color: AppColors.brandPrimaryDark,
        fontWeight: FontWeight.w700,
      ),
      helperStyle: AppTypography.caption.copyWith(color: AppColors.textMuted),
      hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
      prefixIconColor: AppColors.textMuted,
      border: fieldBorder(AppColors.border),
      enabledBorder: fieldBorder(AppColors.border),
      focusedBorder: fieldBorder(AppColors.brandPrimary, width: 1.4),
      errorBorder: fieldBorder(AppColors.danger),
      focusedErrorBorder: fieldBorder(AppColors.danger, width: 1.4),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: AppColors.textInverted,
        disabledBackgroundColor: AppColors.surfaceSubtle,
        disabledForegroundColor: AppColors.textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        hoverColor: AppColors.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surfaceMuted,
      selectedColor: AppColors.brandPrimary.withValues(alpha: 0.12),
      disabledColor: AppColors.surfaceSubtle,
      labelStyle: AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      secondaryLabelStyle: AppTypography.caption.copyWith(
        color: AppColors.brandPrimaryDark,
        fontWeight: FontWeight.w700,
      ),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
    ),
  );
}

class _SessaoFormHeader extends StatelessWidget {
  final String title;

  const _SessaoFormHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Voltar',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.brandPrimaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.pageTitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: 'Fechar',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
