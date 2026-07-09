import 'package:flutter/foundation.dart';
import '../models/disciplina.dart';
import '../models/material_estudo.dart';
import '../models/nota_estudo.dart';
import '../services/api_service.dart';

class MateriaisProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<MaterialEstudo> _materiais = [];
  List<Disciplina> _disciplinas = [];
  String? _selectedDisciplinaId;
  String? _selectedTipo;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  List<MaterialEstudo> get materiais => _materiais;
  List<Disciplina> get disciplinas => _disciplinas;
  String? get selectedDisciplinaId => _selectedDisciplinaId;
  String? get selectedTipo => _selectedTipo;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    await Future.wait([loadDisciplinas(), loadMateriais()]);
  }

  Future<void> loadDisciplinas() async {
    _disciplinas = await _api.getDisciplinas();
    notifyListeners();
  }

  Future<void> loadMateriais() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final materiais = await _api.getMateriais(
        disciplinaId: _selectedDisciplinaId,
        tipo: _selectedTipo,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      // Notas de estudo tambem vivem em materiais-estudo; nao exibi-las aqui.
      _materiais =
          materiais.where((m) => !NotaEstudo.ehNota(m)).toList();
    } catch (e) {
      _error = 'Erro ao carregar materiais.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setDisciplinaFilter(String? disciplinaId) {
    _selectedDisciplinaId = disciplinaId;
    loadMateriais();
  }

  void setTipoFilter(String? tipo) {
    _selectedTipo = tipo;
    loadMateriais();
  }

  void setSearch(String query) {
    _searchQuery = query;
    loadMateriais();
  }

  Future<bool> addMaterial(Map<String, dynamic> data) async {
    final result = await _api.createMaterial(data);
    if (result != null) {
      await loadMateriais();
      return true;
    }
    return false;
  }

  Future<bool> updateMaterial(String id, Map<String, dynamic> data) async {
    final result = await _api.updateMaterial(id, data);
    if (result != null) {
      final idx = _materiais.indexWhere((m) => m.id == id);
      if (idx >= 0) _materiais[idx] = result;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteMaterial(String id) async {
    final ok = await _api.deleteMaterial(id);
    if (ok) {
      _materiais.removeWhere((m) => m.id == id);
      notifyListeners();
    }
    return ok;
  }
}
