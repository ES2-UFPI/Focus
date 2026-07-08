import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/insights/insight_feed_section.dart';

import '../../fixtures/insights_fixtures.dart';

void main() {
  test('groups severities and excludes insufficient evidence', () {
    final groups = groupInsightsByPriority(getInsightsFixture());

    expect(groups.attention.first.severidade, 'critico');
    expect(
      groups.attention.every(
        (item) => item.severidade == 'critico' || item.severidade == 'atencao',
      ),
      isTrue,
    );
    expect(
      groups.discoveries.every(
        (item) => item.severidade == 'positivo' || item.severidade == 'info',
      ),
      isTrue,
    );
    expect(
      [
        ...groups.attention,
        ...groups.discoveries,
      ].where((item) => item.confianca == 'insuficiente'),
      isEmpty,
    );
  });

  test('applies the subject filter to both priority groups', () {
    final groups = groupInsightsByPriority(
      getInsightsFixture(),
      disciplina: 'Estruturas de Dados',
    );

    expect(
      [
        ...groups.attention,
        ...groups.discoveries,
      ].every((item) => item.disciplina == 'Estruturas de Dados'),
      isTrue,
    );
  });
}
