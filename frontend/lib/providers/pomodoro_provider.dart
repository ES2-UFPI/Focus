import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../models/disciplina_model.dart';
import '../services/disciplina_service.dart';

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
  final int diasRestantes;
  final String tipo;
  final int planejado;
  const _MetaDisciplina(this.diasRestantes, this.tipo, this.planejado);
}

const List<String> _kTiposMeta = ['Prova', 'Trabalho', 'Seminário', 'Exercícios'];

/// Estado do timer Pomodoro. Mantido em memória (não persiste no backend);
/// só a lista de disciplinas vem da API.
class PomodoroProvider extends ChangeNotifier {
  final DisciplinaService _disciplinaService;

  PomodoroProvider({DisciplinaService? disciplinaService})
      : _disciplinaService = disciplinaService ?? DisciplinaService() {
    _carregarDisciplinas();
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
  final Map<String, _MetaDisciplina> _metas = {};
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

  Future<void> _carregarDisciplinas() async {
    try {
      final lista = await _disciplinaService.getDisciplinas();
      disciplinas = lista.where((d) => d.ativo).toList();
      final rnd = Random(42);
      for (final d in disciplinas) {
        _metas[d.id] = _MetaDisciplina(
          1 + rnd.nextInt(7),
          _kTiposMeta[rnd.nextInt(_kTiposMeta.length)],
          3 + rnd.nextInt(6),
        );
        _doneCounts[d.id] = 0;
      }
      remainingSeconds = durations[mode]! * 60;
    } catch (e) {
      error = 'Não foi possível carregar as disciplinas.';
    } finally {
      loading = false;
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

  _MetaDisciplina? get _metaSelecionada {
    final d = disciplinaSelecionada;
    if (d == null) return null;
    return _metas[d.id];
  }

  int get doneCountSelecionado {
    final d = disciplinaSelecionada;
    if (d == null) return 0;
    return _doneCounts[d.id] ?? 0;
  }

  String get dueText {
    final meta = _metaSelecionada;
    if (meta == null) return 'sem meta definida';
    final dd = meta.diasRestantes;
    final prazo = dd <= 0 ? 'entrega hoje' : (dd == 1 ? 'falta 1 dia' : 'faltam $dd dias');
    return '$prazo · ${meta.tipo}';
  }

  Color get dueColor {
    final dd = _metaSelecionada?.diasRestantes ?? 99;
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
        history.insert(
          0,
          PomodoroHistoryEntry(
            disciplinaNome: d.nome,
            cor: _parseHex(d.cor),
            duracaoMinutos: durations[PomodoroMode.foco]!,
            hora: _horaAtual(),
          ),
        );
        if (history.length > 6) history.removeRange(6, history.length);
        _doneCounts[d.id] = (_doneCounts[d.id] ?? 0) + 1;
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
