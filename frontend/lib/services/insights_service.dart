import '../data/insights_mock.dart';
import '../models/insights_model.dart';

/// Ponto único de acesso aos dados do módulo Insights.
///
/// Hoje serve a massa local (`insights_mock.dart`). A fase de dados troca
/// apenas o corpo destes métodos por chamadas ao backend
/// (`GET /api/insights/`, `GET /api/insights/evolucao/`,
/// `POST /api/insights/{id}/feedback`), **sem alterar a UI** que consome esta
/// interface — a tela já trata carregamento, erro e reenvio.
class InsightsService {
  const InsightsService();

  /// Lista de insights do aluno autenticado.
  Future<List<Insight>> fetchInsights() async => getInsightsMock();

  /// Marcos da jornada exibidos na aba Evolução.
  Future<List<InsightJourneyEvent>> fetchJourney() async => getJornadaMock();

  /// Resumo temporal usado no panorama, comparações e experimentos.
  Future<InsightsDashboard> fetchDashboard() async =>
      getInsightsDashboardMock();

  /// Envia o feedback do usuário sobre um insight.
  ///
  /// No mock é um no-op; na fase de dados vira
  /// `POST /api/insights/{id}/feedback`, alimentando personalização
  /// determinística (rebaixar rejeitados, ajustar limiares, reavaliar depois).
  Future<void> submitFeedback({
    required String insightId,
    required bool useful,
    String? reason,
  }) async {}
}
