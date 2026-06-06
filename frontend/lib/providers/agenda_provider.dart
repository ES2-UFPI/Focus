/// Provider de estado da tela de Agenda Acadêmica.
///
/// Gerencia o ciclo de vida da requisição (loading → sucesso / erro),
/// a filtragem por tipo de item e o agrupamento cronológico por data
/// para facilitar a renderização da timeline.
library;

import 'package:flutter/foundation.dart';

import '../models/agenda_model.dart';
import '../services/agenda_service.dart';

class AgendaProvider extends ChangeNotifier {
  final AgendaService _service;

  AgendaProvider({AgendaService? service})
      : _service = service ?? AgendaService();

  // ---------------------------------------------------------------------------
  // Estado interno
  // ---------------------------------------------------------------------------

  List<AgendaItem> _itens = [];
  List<AgendaRecomendacao> _recomendacoes = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'TODOS';

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<AgendaItem> get itens => _itens;
  List<AgendaRecomendacao> get recomendacoes => _recomendacoes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;

  /// Itens filtrados de acordo com o filtro ativo.
  List<AgendaItem> get itensFiltrados {
    switch (_selectedFilter) {
      case 'EVENTOS':
        return _itens.where((i) => i.isEvento).toList();
      case 'SESSOES':
        return _itens.where((i) => i.isSessao).toList();
      default:
        return _itens;
    }
  }

  /// Itens filtrados e agrupados por data (`YYYY-MM-DD`).
  ///
  /// Retorna um [Map] ordenado cronologicamente onde a chave é a data textual
  /// e o valor é a lista de itens daquele dia, já na ordem original fornecida
  /// pela API (ordenados por `timestamp`).
  Map<String, List<AgendaItem>> get itensAgrupadosPorData {
    final map = <String, List<AgendaItem>>{};
    for (final item in itensFiltrados) {
      map.putIfAbsent(item.data, () => []).add(item);
    }
    return map;
  }

  // ---------------------------------------------------------------------------
  // Ações
  // ---------------------------------------------------------------------------

  /// Busca os dados da agenda na API.
  ///
  /// Quando [isRefresh] é `true` (Pull-To-Refresh), o estado de carregamento
  /// **não** é ativado para evitar flashes visuais na interface — o
  /// [RefreshIndicator] nativo já fornece feedback ao usuário.
  Future<void> fetchAgenda({bool isRefresh = false}) async {
    if (!isRefresh) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await _service.getAgenda();
      _itens = response.itens;
      _recomendacoes = response.recomendacoes;
      _errorMessage = null;
    } on AgendaServiceException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Ocorreu um erro inesperado ao carregar a agenda.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Altera o filtro ativo e reconstrói a UI.
  void setFilter(String novoFiltro) {
    if (_selectedFilter == novoFiltro) return;
    _selectedFilter = novoFiltro;
    notifyListeners();
  }
}
