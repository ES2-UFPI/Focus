import 'package:flutter/foundation.dart';

import '../models/disciplina.dart';
import '../models/nota_estudo.dart';
import '../services/notas_service.dart';

enum NotasModo { vazio, detalhe, formulario }

class NotasProvider extends ChangeNotifier {
  final NotasService _service;

  NotasProvider({NotasService? service})
      : _service = service ?? NotasService();

  bool _carregando = false;
  bool _salvando = false;
  String? _erro;
  List<NotaEstudo> _notas = [];
  List<Disciplina> _disciplinas = [];
  String _busca = '';
  String? _filtroDisciplinaId; // null = todas
  String? _notaSelecionadaId;
  NotasModo _modo = NotasModo.vazio;
  NotaEstudo? _emEdicao; // nota carregada no formulario (null = nova)

  bool get carregando => _carregando;
  bool get salvando => _salvando;
  String? get erro => _erro;
  List<Disciplina> get disciplinas => _disciplinas;
  String get busca => _busca;
  String? get filtroDisciplinaId => _filtroDisciplinaId;
  NotasModo get modo => _modo;
  NotaEstudo? get emEdicao => _emEdicao;
  List<NotaEstudo> get todasNotas => _notas;

  NotaEstudo? get notaSelecionada {
    if (_notaSelecionadaId == null) return null;
    for (final n in _notas) {
      if (n.id == _notaSelecionadaId) return n;
    }
    return null;
  }

  List<NotaEstudo> get notasFiltradas {
    final q = _busca.toLowerCase().trim();
    return _notas.where((n) {
      if (_filtroDisciplinaId != null &&
          n.disciplinaId != _filtroDisciplinaId) {
        return false;
      }
      if (q.isEmpty) return true;
      final texto =
          '${n.titulo} ${n.disciplinaNome} ${n.secao('obs').join(' ')}'
              .toLowerCase();
      return texto.contains(q);
    }).toList();
  }

  int contagemPorDisciplina(String? disciplinaId) {
    if (disciplinaId == null) return _notas.length;
    return _notas.where((n) => n.disciplinaId == disciplinaId).length;
  }

  Future<void> carregar() async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      final resultados = await Future.wait([
        _service.listarNotas(),
        _service.listarDisciplinas(),
      ]);
      _notas = resultados[0] as List<NotaEstudo>;
      _disciplinas = resultados[1] as List<Disciplina>;
      if (_notaSelecionadaId == null && _notas.isNotEmpty) {
        _notaSelecionadaId = _notas.first.id;
        _modo = NotasModo.detalhe;
      }
    } catch (e) {
      _erro = 'Não foi possível carregar as notas.';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  void definirBusca(String valor) {
    _busca = valor;
    notifyListeners();
  }

  void definirFiltroDisciplina(String? disciplinaId) {
    _filtroDisciplinaId = disciplinaId;
    notifyListeners();
  }

  void selecionarNota(String id) {
    _notaSelecionadaId = id;
    _modo = NotasModo.detalhe;
    _emEdicao = null;
    notifyListeners();
  }

  void novaNota() {
    _emEdicao = null;
    _modo = NotasModo.formulario;
    notifyListeners();
  }

  void editarNotaSelecionada() {
    final nota = notaSelecionada;
    if (nota == null) return;
    _emEdicao = nota;
    _modo = NotasModo.formulario;
    notifyListeners();
  }

  /// Usado no layout estreito para voltar a lista de notas.
  void voltarParaLista() {
    _emEdicao = null;
    _modo = NotasModo.vazio;
    notifyListeners();
  }

  void cancelarFormulario() {
    _emEdicao = null;
    _modo = notaSelecionada != null ? NotasModo.detalhe : NotasModo.vazio;
    notifyListeners();
  }

  Future<bool> salvar(NotaEstudo nota) async {
    _salvando = true;
    _erro = null;
    notifyListeners();
    try {
      final salva = await _service.salvarNota(nota);
      if (salva == null) {
        _erro = 'Não foi possível salvar a nota.';
        return false;
      }
      final idx = _notas.indexWhere((n) => n.id == salva.id);
      if (idx >= 0) {
        _notas[idx] = salva;
      } else {
        _notas.insert(0, salva);
      }
      _notaSelecionadaId = salva.id;
      _modo = NotasModo.detalhe;
      _emEdicao = null;
      return true;
    } catch (e) {
      _erro = 'Não foi possível salvar a nota.';
      return false;
    } finally {
      _salvando = false;
      notifyListeners();
    }
  }

  Future<bool> excluirNotaSelecionada() async {
    final nota = notaSelecionada;
    if (nota?.id == null) return false;
    try {
      final ok = await _service.excluirNota(nota!.id!);
      if (!ok) {
        _erro = 'Não foi possível excluir a nota.';
        notifyListeners();
        return false;
      }
      _notas.removeWhere((n) => n.id == nota.id);
      _notaSelecionadaId = null;
      _modo = NotasModo.vazio;
      notifyListeners();
      return true;
    } catch (e) {
      _erro = 'Não foi possível excluir a nota.';
      notifyListeners();
      return false;
    }
  }
}
