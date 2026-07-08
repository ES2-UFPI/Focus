import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/insights_mock.dart';
import 'package:frontend/widgets/insights/insight_evolution_card_strategy.dart';

void main() {
  test('health routine insights use a source context instead of discipline', () {
    final insight = getInsightsMock().firstWhere(
      (item) => item.tipo == 'desgaste',
    );

    final presentation = EvolutionCardStrategyResolver.defaults.resolve(
      insight,
    );

    expect(presentation.title, 'Menos estudo tarde');
    expect(presentation.contextLabel, 'Fonte');
    expect(presentation.contextValue, 'Sono e rotina');
  });

  test('study management insights keep discipline context', () {
    final insight = getInsightsMock().firstWhere(
      (item) => item.tipo == 'taxa_furo',
    );

    final presentation = EvolutionCardStrategyResolver.defaults.resolve(
      insight,
    );

    expect(presentation.title, 'Sexta à noite evitada');
    expect(presentation.contextLabel, 'Disciplina');
    expect(presentation.contextValue, 'Banco de Dados');
    expect(presentation.delta, '-20%');
  });
}
