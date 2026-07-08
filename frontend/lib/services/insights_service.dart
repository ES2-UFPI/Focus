import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/network/api_client.dart';
import '../models/insights_model.dart';

/// Ponto único de acesso aos dados do módulo Insights.
///
/// Consome o backend real:
/// - `GET  /api/insights/`               → [fetchInsights]
/// - `GET  /api/insights/evolucao/`      → [fetchJourney] / [fetchDashboard]
/// - `POST /api/insights/{id}/feedback/` → [submitFeedback]
///
/// A UI que consome esta interface (tela, cards) não precisa saber a origem
/// dos dados — ela já trata carregamento, erro e reenvio.
class InsightsService {
  /// Cliente HTTP injetável (facilita testes). Quando nulo, usa um cliente
  /// padrão a cada chamada. Mantido opcional para preservar o construtor
  /// `const` usado pela tela e pelos testes de widget.
  final http.Client? client;

  const InsightsService({this.client});

  http.Client get _http => client ?? http.Client();

  /// Lista de insights do aluno autenticado.
  Future<List<Insight>> fetchInsights() async {
    final uri = Uri.parse('$kBaseUrl/api/insights/');
    final response = await _http.get(uri, headers: kDefaultHeaders);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map(Insight.fromJson)
          .toList();
    }
    throw InsightsServiceException(
      'Erro ao buscar insights. Status: ${response.statusCode}',
    );
  }

  /// Melhorias observadas exibidas na aba Evolução.
  ///
  /// Vêm do campo `jornada` de `GET /api/insights/evolucao/`. A lista pode ser
  /// vazia quando ainda não há uma melhoria objetiva a mostrar — a UI já trata
  /// esse caso.
  Future<List<InsightJourneyEvent>> fetchJourney() async {
    final uri = Uri.parse('$kBaseUrl/api/insights/evolucao/');
    final response = await _http.get(uri, headers: kDefaultHeaders);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final jornada = data['jornada'];
      if (jornada is! List) return const [];
      return jornada
          .whereType<Map<String, dynamic>>()
          .map(InsightJourneyEvent.fromJson)
          .toList();
    }
    throw InsightsServiceException(
      'Erro ao buscar evolução. Status: ${response.statusCode}',
    );
  }

  /// Resumo temporal usado no panorama, comparações e experimentos.
  Future<InsightsDashboard> fetchDashboard() async {
    final uri = Uri.parse('$kBaseUrl/api/insights/evolucao/');
    final response = await _http.get(uri, headers: kDefaultHeaders);
    if (response.statusCode == 200) {
      return InsightsDashboard.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw InsightsServiceException(
      'Erro ao buscar evolução. Status: ${response.statusCode}',
    );
  }

  /// Envia o feedback do usuário sobre um insight
  /// (`POST /api/insights/{id}/feedback/`).
  Future<void> submitFeedback({
    required String insightId,
    required bool useful,
    String? reason,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/insights/$insightId/feedback/');
    final response = await _http.post(
      uri,
      headers: kDefaultHeaders,
      body: jsonEncode({'useful': useful, 'reason': reason}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw InsightsServiceException(
        'Erro ao enviar feedback. Status: ${response.statusCode}',
      );
    }
  }
}

class InsightsServiceException implements Exception {
  final String message;
  const InsightsServiceException(this.message);

  @override
  String toString() => message;
}
