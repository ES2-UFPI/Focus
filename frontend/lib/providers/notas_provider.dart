import 'dart:ui';

import 'package:flutter/foundation.dart';
import '../models/disciplina.dart';
import '../models/nota.dart';
import '../services/api_service.dart';

enum NotasView { vazio, detalhe, formulario }

class NotasProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Nota> _notas = [];
  List<Disciplina> _disciplinas = [];
  String? _filtroDisciplinaId;
  String _searchQuery = '';
  String? _selectedId;
  NotasView _view = NotasView.vazio;
  bool _isLoading = false;
  String? _error;

  /// Nota em edição no formulário; null quando o formulário cria uma nova.
  Nota? _editing;

  List<Disciplina> get disciplinas => _disciplinas;
  String? get filtroDisciplinaId => _filtroDisciplinaId;
  String get searchQuery => _searchQuery;
  NotasView get view => _view;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Nota? get editing => _editing;
  int get totalNotas => _notas.length;

  Nota? get selecionada {
    if (_selectedId == null) return null;
    for (final n in _notas) {
      if (n.id == _selectedId) return n;
    }
    return null;
  }

  List<Nota> get notasFiltradas {
    final q = _searchQuery.toLowerCase().trim();
    return _notas.where((n) {
      if (_filtroDisciplinaId != null && n.disciplinaId != _filtroDisciplinaId) {
        return false;
      }
      if (q.isEmpty) return true;
      final conteudo = [
        n.titulo,
        n.disciplinaNome,
        for (final sec in kNotaSecoes) ...n.itensDe(sec.key),
      ].join(' ').toLowerCase();
      return conteudo.contains(q);
    }).toList();
  }

  int contagemPorDisciplina(String disciplinaId) =>
      _notas.where((n) => n.disciplinaId == disciplinaId).length;

  Future<void> init() async {
    await Future.wait([loadDisciplinas(), loadNotas()]);
    final filtradas = notasFiltradas;
    if (_selectedId == null && filtradas.isNotEmpty) {
      _selectedId = filtradas.first.id;
      _view = NotasView.detalhe;
      notifyListeners();
    }
  }

  Future<void> loadDisciplinas() async {
    try {
      _disciplinas = await _api.getDisciplinas();
    } catch (e) {
      if (kDebugMode) debugPrint('Erro ao carregar disciplinas: $e');
    }
    notifyListeners();
  }

  Future<void> loadNotas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final materiais = await _api.getMateriais(tipo: 'Resumo');
      _notas = materiais
          .map(Nota.fromMaterial)
          .whereType<Nota>()
          .toList();
    } catch (e) {
      _error = 'Erro ao carregar notas.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFiltroDisciplina(String? disciplinaId) {
    _filtroDisciplinaId = disciplinaId;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selecionar(String id) {
    _selectedId = id;
    _view = NotasView.detalhe;
    _editing = null;
    notifyListeners();
  }

  void abrirNova() {
    _editing = null;
    _view = NotasView.formulario;
    notifyListeners();
  }

  void abrirEdicao() {
    final nota = selecionada;
    if (nota == null) return;
    _editing = nota;
    _view = NotasView.formulario;
    notifyListeners();
  }

  /// Em telas estreitas, esconde o painel de leitura e volta para a lista.
  void voltarParaLista() {
    _editing = null;
    _view = NotasView.vazio;
    notifyListeners();
  }

  void cancelarFormulario() {
    _editing = null;
    _view = selecionada != null ? NotasView.detalhe : NotasView.vazio;
    notifyListeners();
  }

  /// Cor cadastrada da disciplina da nota; indigo padrão como fallback.
  Color corDaNota(Nota nota) {
    for (final d in _disciplinas) {
      if (d.id == nota.disciplinaId) return corFromHex(d.cor);
    }
    return corFromHex('#6366F1');
  }

  Future<bool> salvar({
    required String titulo,
    required String disciplinaId,
    required Map<String, List<String>> secoes,
  }) async {
    final payload = Nota.toMaterialJson(
      titulo: titulo,
      disciplinaId: disciplinaId,
      secoes: secoes,
    );

    final editId = _editing?.id;
    final result = editId != null
        ? await _api.updateMaterial(editId, payload)
        : await _api.createMaterial(payload);
    if (result == null) return false;

    await loadNotas();
    _selectedId = result.id;
    _view = NotasView.detalhe;
    _editing = null;
    notifyListeners();
    return true;
  }

  Future<bool> excluir(String id) async {
    final ok = await _api.deleteMaterial(id);
    if (ok) {
      _notas.removeWhere((n) => n.id == id);
      if (_selectedId == id) {
        _selectedId = null;
        _view = NotasView.vazio;
      }
      notifyListeners();
    }
    return ok;
  }
}
