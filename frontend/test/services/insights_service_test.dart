import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/insights_model.dart';
import 'package:frontend/services/insights_service.dart';

void main() {
  const service = InsightsService();

  test('fetchInsights resolves the insights list', () async {
    final insights = await service.fetchInsights();

    expect(insights, hasLength(6));
    expect(insights.first, isA<Insight>());
  });

  test('fetchJourney resolves the journey events', () async {
    final journey = await service.fetchJourney();

    expect(journey, hasLength(6));
    expect(journey.first, isA<InsightJourneyEvent>());
  });

  test('fetchDashboard resolves comparisons and experiments', () async {
    final dashboard = await service.fetchDashboard();

    expect(dashboard, isA<InsightsDashboard>());
    expect(dashboard.dimensoes, hasLength(5));
    expect(dashboard.comparacoes, hasLength(3));
    expect(dashboard.experimentos, hasLength(3));
  });

  test('submitFeedback completes without throwing', () async {
    await expectLater(
      service.submitFeedback(insightId: 'ins-123', useful: false, reason: 'x'),
      completes,
    );
  });
}
