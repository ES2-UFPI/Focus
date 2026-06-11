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

  /// Data de referência (foco) para visualização do calendário semanal.
  DateTime _dataFocal = DateTime.now();

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<AgendaItem> get itens => _itens;
  List<AgendaRecomendacao> get recomendacoes => _recomendacoes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;
  DateTime get dataFocal => _dataFocal;

  /// Retorna a segunda-feira da semana contendo a [dataFocal].
  DateTime get inicioDaSemanaFocal {
    final diaSemana = _dataFocal.weekday;
    final dataSemHora = DateTime(_dataFocal.year, _dataFocal.month, _dataFocal.day);
    // Em Dart, Segunda = 1, Domingo = 7. Subtraímos (weekday - 1) dias para chegar na Segunda.
    return dataSemHora.subtract(Duration(days: diaSemana - 1));
  }

  /// Retorna o domingo da semana contendo a [dataFocal].
  DateTime get fimDaSemanaFocal {
    return inicioDaSemanaFocal.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }

  /// Itens filtrados de acordo com o filtro ativo (Todos / Eventos / Sessões).
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
  Map<String, List<AgendaItem>> get itensAgrupadosPorData {
    final map = <String, List<AgendaItem>>{};
    for (final item in itensFiltrados) {
      map.putIfAbsent(item.data, () => []).add(item);
    }
    return map;
  }

  // ── Getters para o MODO LISTA ──────────────────────────────────────────────

  /// Retorna os itens pendentes (não concluídos) de acordo com o tipo correspondente.
  List<AgendaItem> get itensPendentes {
    return itensFiltrados.where((item) {
      if (item.isEvento) {
        return item.concluido != true;
      } else {
        return item.status != 'CONCLUIDO';
      }
    }).toList();
  }

  /// Retorna os itens concluídos de acordo com o tipo correspondente.
  List<AgendaItem> get itensConcluidos {
    return itensFiltrados.where((item) {
      if (item.isEvento) {
        return item.concluido == true;
      } else {
        return item.status == 'CONCLUIDO';
      }
    }).toList();
  }

  /// Retorna os itens cujas datas estão nos próximos 30 dias (a partir de hoje).
  List<AgendaItem> get itensProximos30Dias {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final limite30Dias = hojeSemHora.add(const Duration(days: 30, hours: 23, minutes: 59, seconds: 59));

    return itensFiltrados.where((item) {
      final itemDate = DateTime(item.timestamp.year, item.timestamp.month, item.timestamp.day);
      return !itemDate.isBefore(hojeSemHora) && !itemDate.isAfter(limite30Dias);
    }).toList();
  }

  // ── Getters para o MODO CALENDÁRIO ─────────────────────────────────────────

  /// Retorna os itens filtrados que pertencem à semana da [dataFocal] (Segunda a Domingo).
  List<AgendaItem> get itensDaSemanaFocal {
    final inicio = inicioDaSemanaFocal;
    final fim = fimDaSemanaFocal;

    return itensFiltrados.where((item) {
      // Usar a propriedade timestamp do item para verificação
      return !item.timestamp.isBefore(inicio) && !item.timestamp.isAfter(fim);
    }).toList();
  }

  /// Retorna os itens da semana focal agrupados por data ISO (`YYYY-MM-DD`).
  Map<String, List<AgendaItem>> get itensDaSemanaFocalAgrupadosPorData {
    final map = <String, List<AgendaItem>>{};
    for (final item in itensDaSemanaFocal) {
      map.putIfAbsent(item.data, () => []).add(item);
    }
    return map;
  }

  // ---------------------------------------------------------------------------
  // Ações de Navegação Temporal
  // ---------------------------------------------------------------------------

  /// Avança a semana focal em 7 dias.
  void avancarSemana() {
    _dataFocal = _dataFocal.add(const Duration(days: 7));
    notifyListeners();
  }

  /// Retrocede a semana focal em 7 dias.
  void retrocederSemana() {
    _dataFocal = _dataFocal.subtract(const Duration(days: 7));
    notifyListeners();
  }

  /// Define a semana focal para a semana atual (hoje).
  void irParaHoje() {
    final hoje = DateTime.now();
    if (_dataFocal.year == hoje.year &&
        _dataFocal.month == hoje.month &&
        _dataFocal.day == hoje.day) {
      return;
    }
    _dataFocal = hoje;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Ações de Carregamento
  // ---------------------------------------------------------------------------

  /// Busca os dados da agenda na API.
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
    if (_selectedFilter == novoFiltro) {
      return;
    }
    _selectedFilter = novoFiltro;
    notifyListeners();
  }
}
