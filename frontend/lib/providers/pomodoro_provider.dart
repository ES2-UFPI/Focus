import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/disciplina_model.dart';
import '../services/disciplina_service.dart';
import '../services/agenda_service.dart';
import '../services/sessao_estudo_service.dart';

enum PomodoroMode { foco, curta, longa }

class PomodoroHistoryEntry {
  final String disciplinaNome;
  final Color cor;
  final int duracaoMinutos;
  final String hora;

  PomodoroHistoryEntry({
    required this.disciplinaNome,
    required this.cor,
    required this.duracaoMinutos,
    required this.hora,
  });
}

class _MetaDisciplina {
  /// -1 quando a disciplina não tem evento acadêmico com prazo definido.
  final int diasRestantes;
  final String tipo;
  final String titulo;
  final int planejado;
  /// Id do EventoAcademico de origem (null quando é o fallback "sem prazo").
  final String? eventoId;
  const _MetaDisciplina(this.diasRestantes, this.tipo, this.titulo, this.planejado, this.eventoId);
}

/// Estado do timer Pomodoro. Disciplinas, metas (via Agenda) e progresso da
/// semana (via SessaoEstudo) vêm do backend; cada ciclo de foco concluído é
/// persistido como uma sessão de estudo CONCLUIDO.
class PomodoroProvider extends ChangeNotifier {
  final DisciplinaService _disciplinaService;
  final AgendaService _agendaService;
  final SessaoEstudoService _sessaoEstudoService;

  PomodoroProvider({
    DisciplinaService? disciplinaService,
    AgendaService? agendaService,
    SessaoEstudoService? sessaoEstudoService,
  })  : _disciplinaService = disciplinaService ?? DisciplinaService(),
        _agendaService = agendaService ?? AgendaService(),
        _sessaoEstudoService = sessaoEstudoService ?? SessaoEstudoService() {
    _carregarTudo();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  static const Map<PomodoroMode, Color> modeColors = {
    PomodoroMode.foco: Color(0xFF6366F1),
    PomodoroMode.curta: Color(0xFF4CAF50),
    PomodoroMode.longa: Color(0xFF7E57C2),
  };

  static const Map<PomodoroMode, String> modeLabels = {
    PomodoroMode.foco: 'Foco',
    PomodoroMode.curta: 'Pausa curta',
    PomodoroMode.longa: 'Pausa longa',
  };

  late final Timer _ticker;

  bool loading = true;
  String? error;
  List<Disciplina> disciplinas = [];
  final Map<String, List<_MetaDisciplina>> _metasPorDisciplina = {};
  final Map<String, int> _metaIndexPorDisciplina = {};
  final Map<String, int> _doneCounts = {};

  final Map<PomodoroMode, int> durations = {
    PomodoroMode.foco: 25,
    PomodoroMode.curta: 5,
    PomodoroMode.longa: 15,
  };
  final int cyclesPerRound = 4;
  final bool autoStartBreaks = false;

  PomodoroMode mode = PomodoroMode.foco;
  bool running = false;
  int remainingSeconds = 25 * 60;
  int cycle = 1;
  int selectedIndex = 0;

  int sessionsToday = 0;
  int focusSecondsToday = 0;
  final List<double> weekHours = List.filled(7, 0.0);
  final List<PomodoroHistoryEntry> history = [];

  Future<void> _carregarTudo() async {
    try {
      final lista = await _disciplinaService.getDisciplinas();
      disciplinas = lista.where((d) => d.ativo).toList();
      for (final d in disciplinas) {
        _doneCounts[d.id] = 0;
      }
      remainingSeconds = durations[mode]! * 60;
    } catch (e) {
      error = 'Não foi possível carregar as disciplinas.';
    } finally {
      loading = false;
      notifyListeners();
    }
    // Falhas nas duas chamadas abaixo não devem travar a tela: o Pomodoro
    // continua funcional com metas/histórico vazios se a rede falhar.
    await _carregarMetasReais();
    await _carregarProgressoSemana();
  }

  /// Usa a Agenda (eventos acadêmicos por disciplina) para listar, por
  /// disciplina, cada evento pendente (Prova, Trabalho etc.) como uma meta
  /// selecionável — evita misturar prazos diferentes da mesma disciplina.
  /// meta_horas_semanais da disciplina define quantos pomodoros de foco são
  /// "planejados" na semana (igual para todas as metas da disciplina).
  Future<void> _carregarMetasReais() async {
    try {
      final agenda = await _agendaService.getAgenda();
      final eventosPendentes = agenda.itens
          .where((i) => i.isEvento && !(i.concluido ?? false))
          .toList();

      for (final d in disciplinas) {
        final eventosDaDisciplina = eventosPendentes
            .where((e) => e.disciplinaId == d.id)
            .toList()
          ..sort((a, b) => (a.diasRestantes ?? 999).compareTo(b.diasRestantes ?? 999));

        final planejado = d.metaHorasSemanais > 0
            ? max(1, (d.metaHorasSemanais * 60 / durations[PomodoroMode.foco]!).round())
            : 0;

        final metas = eventosDaDisciplina
            .map((e) => _MetaDisciplina(
                  e.diasRestantes ?? 0,
                  e.tipoEvento ?? 'Evento',
                  e.titulo,
                  planejado,
                  e.id,
                ))
            .toList();

        if (metas.isEmpty && planejado > 0) {
          metas.add(_MetaDisciplina(-1, '', '', planejado, null));
        }

        _metasPorDisciplina[d.id] = metas;
        _metaIndexPorDisciplina[d.id] = 0;
      }
      notifyListeners();
    } catch (_) {
      // Sem prazos reais disponíveis: dueText cai no fallback "sem meta definida".
    }
  }

  /// Usa as sessões concluídas da semana atual para preencher o histórico,
  /// as horas por dia da semana e as sessões concluídas hoje.
  Future<void> _carregarProgressoSemana() async {
    try {
      final sessoes = await _sessaoEstudoService.getSemanaAtual();
      final concluidas = sessoes.where((s) => s.status == 'CONCLUIDO').toList();

      for (var i = 0; i < weekHours.length; i++) {
        weekHours[i] = 0.0;
      }
      sessionsToday = 0;
      focusSecondsToday = 0;
      _doneCounts.updateAll((key, value) => 0);

      final hoje = DateTime.now();
      for (final s in concluidas) {
        final idx = s.inicio.weekday - 1;
        if (idx >= 0 && idx < 7) weekHours[idx] += s.duracaoRealizada / 60.0;
        if (_isMesmoDia(s.inicio, hoje)) {
          sessionsToday++;
          focusSecondsToday += s.duracaoRealizada * 60;
        }
        _doneCounts[s.disciplinaId] = (_doneCounts[s.disciplinaId] ?? 0) + 1;
      }

      concluidas.sort((a, b) => b.inicio.compareTo(a.inicio));
      history
        ..clear()
        ..addAll(concluidas.take(6).map((s) {
          final match = disciplinas.where((d) => d.id == s.disciplinaId);
          final cor = match.isNotEmpty ? _parseHex(match.first.cor) : modeColors[PomodoroMode.foco]!;
          return PomodoroHistoryEntry(
            disciplinaNome: s.disciplinaNome,
            cor: cor,
            duracaoMinutos: s.duracaoRealizada,
            hora: '${s.inicio.hour.toString().padLeft(2, '0')}:${s.inicio.minute.toString().padLeft(2, '0')}',
          );
        }));
      notifyListeners();
    } catch (_) {
      // Sem progresso real disponível: mantém weekHours/history/sessionsToday zerados.
    }
  }

  bool _isMesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Persiste um ciclo de foco concluído como sessão CONCLUIDO no backend.
  /// Nunca bloqueia o timer: falhas de rede só marcam [error] para exibição.
  Future<void> _persistirSessaoConcluida(
    String disciplinaId,
    DateTime inicio,
    DateTime fim,
    int duracaoMinutos,
    String? descricao,
    String? eventoAcademicoId,
  ) async {
    try {
      await _sessaoEstudoService.criarSessaoConcluida(
        disciplinaId: disciplinaId,
        inicio: inicio,
        fim: fim,
        duracaoRealizada: duracaoMinutos,
        descricao: descricao,
        eventoAcademicoId: eventoAcademicoId,
      );
      if (error != null) {
        error = null;
        notifyListeners();
      }
    } on AgendaServiceException catch (e) {
      error = 'Sessão não foi salva no servidor: ${e.message}';
      notifyListeners();
    } catch (_) {
      error = 'Sessão não foi salva no servidor.';
      notifyListeners();
    }
  }

  Disciplina? get disciplinaSelecionada =>
      disciplinas.isEmpty ? null : disciplinas[selectedIndex % disciplinas.length];

  Color get corSelecionada {
    final d = disciplinaSelecionada;
    if (d == null) return modeColors[PomodoroMode.foco]!;
    return _parseHex(d.cor);
  }

  Color get corSelecionadaSuave => Color.lerp(corSelecionada, Colors.white, 0.85)!;

  List<_MetaDisciplina> get _metasDisciplinaSelecionada {
    final d = disciplinaSelecionada;
    if (d == null) return const [];
    return _metasPorDisciplina[d.id] ?? const [];
  }

  _MetaDisciplina? get _metaSelecionada {
    final d = disciplinaSelecionada;
    final lista = _metasDisciplinaSelecionada;
    if (d == null || lista.isEmpty) return null;
    final idx = (_metaIndexPorDisciplina[d.id] ?? 0) % lista.length;
    return lista[idx];
  }

  /// Indica se a disciplina selecionada tem mais de um evento acadêmico
  /// (ex.: Prova e Trabalho), então vale mostrar o seletor de meta.
  bool get temMultiplasMetas => _metasDisciplinaSelecionada.length > 1;

  int get doneCountSelecionado {
    final d = disciplinaSelecionada;
    if (d == null) return 0;
    return _doneCounts[d.id] ?? 0;
  }

  String get dueText {
    final meta = _metaSelecionada;
    if (meta == null) return 'sem meta definida';
    if (meta.diasRestantes < 0) {
      return meta.planejado > 0
          ? 'meta semanal: ${meta.planejado} pomodoros'
          : 'sem meta definida';
    }
    final dd = meta.diasRestantes;
    final prazo = dd <= 0 ? 'entrega hoje' : (dd == 1 ? 'falta 1 dia' : 'faltam $dd dias');
    final rotulo = meta.titulo.isNotEmpty ? meta.titulo : meta.tipo;
    return '$prazo · $rotulo';
  }

  /// Texto que identifica qual meta específica (ex.: Prova vs Trabalho) da
  /// disciplina está selecionada, usado como descrição da sessão persistida.
  String? get _descricaoParaSessao {
    final meta = _metaSelecionada;
    if (meta == null) return null;
    final rotulo = meta.titulo.isNotEmpty ? meta.titulo : meta.tipo;
    if (rotulo.isEmpty) return null;
    if (meta.diasRestantes < 0) return rotulo;
    final dd = meta.diasRestantes;
    final prazo = dd <= 0 ? 'entrega hoje' : (dd == 1 ? 'falta 1 dia' : 'faltam $dd dias');
    return '$rotulo · $prazo';
  }

  Color get dueColor {
    final dd = _metaSelecionada?.diasRestantes;
    if (dd == null || dd < 0) return const Color(0xFF6B7280);
    if (dd <= 1) return const Color(0xFFE53935);
    if (dd <= 3) return const Color(0xFFF9A825);
    return const Color(0xFF6B7280);
  }

  int get goalPlanejado => _metaSelecionada?.planejado ?? 0;

  double get goalPct {
    final planejado = goalPlanejado;
    if (planejado <= 0) return 0;
    return min(1.0, doneCountSelecionado / planejado);
  }

  Color get ringColor => mode == PomodoroMode.foco ? corSelecionada : modeColors[mode]!;
  Color get ringColorSuave => mode == PomodoroMode.foco ? corSelecionadaSuave : Color.lerp(modeColors[mode]!, Colors.white, 0.85)!;

  double get elapsedFraction {
    final total = durations[mode]! * 60;
    if (total == 0) return 0;
    return 1 - remainingSeconds / total;
  }

  String get timeText {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get cycleText => 'Ciclo $cycle de $cyclesPerRound';

  String get focusHojeText {
    final h = focusSecondsToday ~/ 3600;
    final m = (focusSecondsToday % 3600) ~/ 60;
    if (h <= 0) return '${m}m';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  void _tick() {
    if (!running) return;
    if (remainingSeconds > 1) {
      remainingSeconds--;
    } else {
      _completarFase();
    }
    notifyListeners();
  }

  void _completarFase() {
    if (mode == PomodoroMode.foco) {
      final d = disciplinaSelecionada;
      if (d != null) {
        final duracaoMin = durations[PomodoroMode.foco]!;
        final fim = DateTime.now();
        history.insert(
          0,
          PomodoroHistoryEntry(
            disciplinaNome: d.nome,
            cor: _parseHex(d.cor),
            duracaoMinutos: duracaoMin,
            hora: _horaAtual(),
          ),
        );
        if (history.length > 6) history.removeRange(6, history.length);
        _doneCounts[d.id] = (_doneCounts[d.id] ?? 0) + 1;
        // Não aguardado de propósito: falha de rede não pode travar o timer.
        _persistirSessaoConcluida(
          d.id,
          fim.subtract(Duration(minutes: duracaoMin)),
          fim,
          duracaoMin,
          _descricaoParaSessao,
          _metaSelecionada?.eventoId,
        );
      }
      final isRoundEnd = cycle % cyclesPerRound == 0;
      final proximoModo = isRoundEnd ? PomodoroMode.longa : PomodoroMode.curta;
      sessionsToday++;
      focusSecondsToday += durations[PomodoroMode.foco]! * 60;
      final hojeIdx = DateTime.now().weekday - 1;
      weekHours[hojeIdx] += durations[PomodoroMode.foco]! / 60;

      mode = proximoModo;
      remainingSeconds = durations[proximoModo]! * 60;
      running = autoStartBreaks;
    } else {
      final proximoCiclo = mode == PomodoroMode.longa ? 1 : cycle + 1;
      mode = PomodoroMode.foco;
      cycle = proximoCiclo;
      remainingSeconds = durations[PomodoroMode.foco]! * 60;
      running = false;
    }
  }

  void toggle() {
    running = !running;
    notifyListeners();
  }

  void reset() {
    remainingSeconds = durations[mode]! * 60;
    running = false;
    notifyListeners();
  }

  void skip() {
    running = false;
    _completarFase();
    notifyListeners();
  }

  void trocarDisciplina() {
    if (disciplinas.isEmpty) return;
    selectedIndex = (selectedIndex + 1) % disciplinas.length;
    notifyListeners();
  }

  /// Alterna entre os eventos (metas) da disciplina selecionada, ex.: entre
  /// Prova e Trabalho da mesma disciplina. Não faz nada se houver 0 ou 1.
  void trocarMeta() {
    final d = disciplinaSelecionada;
    if (d == null) return;
    final lista = _metasPorDisciplina[d.id] ?? const [];
    if (lista.length <= 1) return;
    final atual = _metaIndexPorDisciplina[d.id] ?? 0;
    _metaIndexPorDisciplina[d.id] = (atual + 1) % lista.length;
    notifyListeners();
  }

  void setMode(PomodoroMode novoModo) {
    mode = novoModo;
    remainingSeconds = durations[novoModo]! * 60;
    running = false;
    notifyListeners();
  }

  void ajustarDuracao(PomodoroMode alvo, int delta) {
    final val = (durations[alvo]! + delta).clamp(1, 90);
    durations[alvo] = val;
    if (alvo == mode && !running) {
      remainingSeconds = val * 60;
    }
    notifyListeners();
  }

  String _horaAtual() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Color _parseHex(String hex) {
    var value = hex.replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.parse(value, radix: 16));
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }
}
