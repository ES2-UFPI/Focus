import 'package:flutter/material.dart';
import '../models/bloco_estudo.dart';
import '../widgets/novo_bloco_dialog.dart';

// ---------------------------------------------------------------------------
// Constantes de disciplina (espelham as do NovoBlocoDialog)
// ---------------------------------------------------------------------------

const _disciplinasCores = {
  'Cálculo I': Color(0xFF5C6BC0),
  'Banco de Dados': Color(0xFF009688),
  'Física': Color(0xFFFF7043),
  'Prog. II': Color(0xFFEC407A),
  'IA': Color(0xFF7E57C2),
};

// ---------------------------------------------------------------------------
// Mock data inicial
// ---------------------------------------------------------------------------

List<BlocoEstudo> _mockBlocos(DateTime semanaInicio) {
  DateTime dia(int offset) => semanaInicio.add(Duration(days: offset));

  return [
    BlocoEstudo(id: '1', disciplina: 'Cálculo I', cor: const Color(0xFF5C6BC0), dia: dia(0), inicio: const TimeOfDay(hour: 8, minute: 0), fim: const TimeOfDay(hour: 10, minute: 0)),
    BlocoEstudo(id: '2', disciplina: 'Banco de Dados', cor: const Color(0xFF009688), dia: dia(0), inicio: const TimeOfDay(hour: 14, minute: 0), fim: const TimeOfDay(hour: 16, minute: 0)),
    BlocoEstudo(id: '3', disciplina: 'Física', cor: const Color(0xFFFF7043), dia: dia(1), inicio: const TimeOfDay(hour: 9, minute: 0), fim: const TimeOfDay(hour: 11, minute: 0)),
    BlocoEstudo(id: '4', disciplina: 'Prog. II', cor: const Color(0xFFEC407A), dia: dia(2), inicio: const TimeOfDay(hour: 10, minute: 0), fim: const TimeOfDay(hour: 12, minute: 0)),
    BlocoEstudo(id: '5', disciplina: 'IA', cor: const Color(0xFF7E57C2), dia: dia(2), inicio: const TimeOfDay(hour: 15, minute: 0), fim: const TimeOfDay(hour: 17, minute: 0)),
    BlocoEstudo(id: '6', disciplina: 'Cálculo I', cor: const Color(0xFF5C6BC0), dia: dia(3), inicio: const TimeOfDay(hour: 8, minute: 0), fim: const TimeOfDay(hour: 9, minute: 30)),
    BlocoEstudo(id: '7', disciplina: 'Banco de Dados', cor: const Color(0xFF009688), dia: dia(4), inicio: const TimeOfDay(hour: 13, minute: 0), fim: const TimeOfDay(hour: 15, minute: 0)),
    BlocoEstudo(id: '8', disciplina: 'Física', cor: const Color(0xFFFF7043), dia: dia(5), inicio: const TimeOfDay(hour: 10, minute: 0), fim: const TimeOfDay(hour: 12, minute: 0)),
  ];
}

// ---------------------------------------------------------------------------
// Tela principal
// ---------------------------------------------------------------------------

class CicloEstudosScreen extends StatefulWidget {
  const CicloEstudosScreen({super.key});

  @override
  State<CicloEstudosScreen> createState() => _CicloEstudosScreenState();
}

class _CicloEstudosScreenState extends State<CicloEstudosScreen> {
  static const int _gridStartHour = 7;
  static const int _gridEndHour = 22;
  static const double _hourHeight = 60.0;
  static const double _colWidth = 100.0;
  static const double _hourLabelWidth = 50.0;

  late DateTime _semanaInicio;
  late List<BlocoEstudo> _blocos;
  bool _modoSemana = true;
  DateTime _diaFoco = DateTime.now();

  @override
  void initState() {
    super.initState();
    _semanaInicio = _calcSemanaInicio(DateTime.now());
    _blocos = _mockBlocos(_semanaInicio);
  }

  DateTime _calcSemanaInicio(DateTime ref) {
    return ref.subtract(Duration(days: ref.weekday - 1));
  }

  List<DateTime> get _diasVisiveis {
    if (_modoSemana) {
      return List.generate(7, (i) => _semanaInicio.add(Duration(days: i)));
    } else {
      return [_diaFoco];
    }
  }

  String get _textoPeriodo {
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    if (_modoSemana) {
      final fim = _semanaInicio.add(const Duration(days: 6));
      final dI = _semanaInicio.day.toString().padLeft(2, '0');
      final dF = fim.day.toString().padLeft(2, '0');
      final mI = meses[_semanaInicio.month - 1];
      final mF = meses[fim.month - 1];
      if (_semanaInicio.month == fim.month) return '$dI–$dF de $mI';
      return '$dI/$mI – $dF/$mF';
    } else {
      const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      return '${dias[_diaFoco.weekday - 1]}, ${_diaFoco.day.toString().padLeft(2, '0')} de ${meses[_diaFoco.month - 1]}';
    }
  }

  bool _isMesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _avancar() {
    setState(() {
      if (_modoSemana) {
        _semanaInicio = _semanaInicio.add(const Duration(days: 7));
      } else {
        _diaFoco = _diaFoco.add(const Duration(days: 1));
      }
    });
  }

  void _retroceder() {
    setState(() {
      if (_modoSemana) {
        _semanaInicio = _semanaInicio.subtract(const Duration(days: 7));
      } else {
        _diaFoco = _diaFoco.subtract(const Duration(days: 1));
      }
    });
  }

  void _irParaHoje() {
    setState(() {
      _diaFoco = DateTime.now();
      _semanaInicio = _calcSemanaInicio(DateTime.now());
    });
  }

  Future<void> _abrirNovoBloco([BlocoEstudo? blocoExistente]) async {
    final diaSelecionado = _modoSemana ? _semanaInicio : _diaFoco;
    final resultado = await showDialog<BlocoEstudo>(
      context: context,
      builder: (_) => NovoBlocoDialog(
        bloco: blocoExistente,
        diaSelecionado: diaSelecionado,
      ),
    );
    if (resultado == null) return;
    setState(() {
      if (blocoExistente != null) {
        final idx = _blocos.indexWhere((b) => b.id == blocoExistente.id);
        if (idx >= 0) _blocos[idx] = resultado;
      } else {
        _blocos = [..._blocos, resultado];
      }
    });
  }

  void _removerBloco(String id) {
    setState(() => _blocos = _blocos.where((b) => b.id != id).toList());
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            _buildToggle(theme),
            Expanded(child: _buildGrid(theme)),
            _buildLegenda(theme),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirNovoBloco(),
        icon: const Icon(Icons.add),
        label: const Text('Novo bloco'),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Cabeçalho
  // -------------------------------------------------------------------------

  Widget _buildHeader(ThemeData theme) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _retroceder,
            visualDensity: VisualDensity.compact,
          ),
          TextButton(
            onPressed: _irParaHoje,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Hoje',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _avancar,
            visualDensity: VisualDensity.compact,
          ),
          const Spacer(),
          Text(_textoPeriodo,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800])),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Toggle Semana / Dia
  // -------------------------------------------------------------------------

  Widget _buildToggle(ThemeData theme) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          SegmentedButton<bool>(
            selected: {_modoSemana},
            onSelectionChanged: (s) => setState(() => _modoSemana = s.first),
            segments: const [
              ButtonSegment(value: true, label: Text('Semana')),
              ButtonSegment(value: false, label: Text('Dia')),
            ],
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Grade horária (baseada no layout de WeeklyCalendarGrid)
  // -------------------------------------------------------------------------

  Widget _buildGrid(ThemeData theme) {
    final dias = _diasVisiveis;
    final totalHoras = _gridEndHour - _gridStartHour + 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHourLabels(totalHoras),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: dias.map((dia) {
                  final blocosDoDia =
                      _blocos.where((b) => _isMesmoDia(b.dia, dia)).toList();
                  final isHoje = _isMesmoDia(dia, DateTime.now());
                  final colW = _modoSemana ? _colWidth : 260.0;

                  return Container(
                    width: colW,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDayHeader(theme, dia, isHoje),
                        Expanded(
                          child: Stack(
                            children: [
                              ...List.generate(totalHoras, (i) => Positioned(
                                    top: i * _hourHeight,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: _hourHeight,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              color: Colors.grey[200]!,
                                              width: 0.5),
                                        ),
                                      ),
                                    ),
                                  )),
                              ...blocosDoDia.map((b) =>
                                  _buildBlocoPositioned(b, colW)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHourLabels(int totalHoras) {
    return Container(
      width: _hourLabelWidth,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 46),
          Expanded(
            child: Stack(
              children: List.generate(totalHoras, (i) {
                final hora = _gridStartHour + i;
                return Positioned(
                  top: i * _hourHeight - 8,
                  left: 0,
                  right: 8,
                  child: Text(
                    '${hora.toString().padLeft(2, '0')}:00',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500]),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(ThemeData theme, DateTime dia, bool isHoje) {
    const nomes = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      width: double.infinity,
      color: isHoje
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
          : Colors.transparent,
      child: Column(
        children: [
          Text(
            nomes[dia.weekday - 1],
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isHoje ? theme.colorScheme.primary : Colors.grey[500]),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHoje ? theme.colorScheme.primary : Colors.transparent,
            ),
            child: Text(
              dia.day.toString().padLeft(2, '0'),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isHoje ? Colors.white : Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlocoPositioned(BlocoEstudo b, double colWidth) {
    final inicioMin = (b.inicio.hour - _gridStartHour) * 60 + b.inicio.minute;
    final fimMin = (b.fim.hour - _gridStartHour) * 60 + b.fim.minute;

    if (inicioMin < 0) return const SizedBox.shrink();

    final top = (inicioMin / 60.0) * _hourHeight;
    final height = ((fimMin - inicioMin) / 60.0) * _hourHeight;
    final displayHeight = height < 28 ? 28.0 : height;

    return Positioned(
      top: top,
      left: 3,
      right: 3,
      height: displayHeight,
      child: GestureDetector(
        onTap: () => _showBlocoMenu(b),
        child: Container(
          decoration: BoxDecoration(
            color: b.cor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: b.cor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.disciplina,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (displayHeight > 36)
                Text(
                  '${b.inicio.hour.toString().padLeft(2, '0')}:${b.inicio.minute.toString().padLeft(2, '0')} – ${b.fim.hour.toString().padLeft(2, '0')}:${b.fim.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlocoMenu(BlocoEstudo b) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: Container(
                width: 16,
                height: 16,
                decoration:
                    BoxDecoration(color: b.cor, shape: BoxShape.circle),
              ),
              title: Text(b.disciplina,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${b.inicio.hour.toString().padLeft(2, '0')}:${b.inicio.minute.toString().padLeft(2, '0')} – ${b.fim.hour.toString().padLeft(2, '0')}:${b.fim.minute.toString().padLeft(2, '0')}'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar bloco'),
              onTap: () {
                Navigator.pop(ctx);
                _abrirNovoBloco(b);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red[600]),
              title: Text('Remover bloco',
                  style: TextStyle(color: Colors.red[600])),
              onTap: () {
                Navigator.pop(ctx);
                _removerBloco(b.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Legenda de disciplinas
  // -------------------------------------------------------------------------

  Widget _buildLegenda(ThemeData theme) {
    final disciplinasUsadas = _blocos.map((b) => b.disciplina).toSet();

    if (disciplinasUsadas.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: disciplinasUsadas.map((d) {
          final cor = _disciplinasCores[d] ?? Colors.grey;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: cor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(d, style: const TextStyle(fontSize: 11)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
