import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/insights_model.dart';
import 'package:frontend/services/insights_service.dart';

void main() {
  const service = InsightsService();

  test('fetchInsights resolves the insights list', () async {
    final insights = await service.fetchInsights();

    expect(insights, hasLength(17));
    expect(insights.first, isA<Insight>());
  });

  test('fetchJourney resolves the journey events', () async {
    final journey = await service.fetchJourney();

    expect(journey, hasLength(4));
    expect(journey.first, isA<InsightJourneyEvent>());
  });

  test('submitFeedback completes without throwing', () async {
    await expectLater(
      service.submitFeedback(insightId: 'ins-123', useful: false, reason: 'x'),
      completes,
    );
  });
}
