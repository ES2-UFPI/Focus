import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/insights_mock.dart';
import 'package:frontend/widgets/insights/insight_recommendations_section.dart';

void main() {
  test('deduplicates actions and keeps only actionable experiments', () {
    final entries = buildInsightRecommendationEntries(
      insights: getInsightsMock(),
      experiments: getInsightsDashboardMock().experimentos,
    );
    final actions = entries
        .where((entry) => entry.kind == InsightRecommendationKind.action)
        .toList();
    final experiments = entries
        .where((entry) => entry.kind == InsightRecommendationKind.experiment)
        .toList();

    expect(actions, hasLength(2));
    expect(actions.map((entry) => entry.insight!.acao!.tipo).toSet(), {
      'agendar_sessao',
      'reagendar',
    });
    expect(
      actions.where((entry) => entry.insight!.acao!.tipo == 'agendar_sessao'),
      hasLength(1),
    );
    expect(experiments, hasLength(2));
    expect(experiments.map((entry) => entry.experiment!.estado).toSet(), {
      'pronto',
      'testando',
    });
    expect(
      entries.any((entry) => entry.experiment?.estado == 'resultado'),
      isFalse,
    );
  });
}
