import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/insights_mock.dart';
import 'package:frontend/models/insights_model.dart';

void main() {
  test('Insight.fromJson reads the future backend contract', () {
    final insight = Insight.fromJson({
      'tipo': 'melhor_horario',
      'titulo': 'Você rende mais de manhã',
      'descricao': 'Descrição',
      'numeros': {'manha': 4.1, 'noite': 2.4, 'delta_pct': 41},
      'amostra': 18,
      'confianca': 'alta',
      'natureza': 'observacional',
      'severidade': 'info',
    });

    expect(insight.tipo, 'melhor_horario');
    expect(insight.numeros['manha'], 4.1);
    expect(insight.amostra, 18);
    expect(insight.confianca, 'alta');
    expect(insight.natureza, 'observacional');
    expect(insight.severidade, 'info');
  });

  test(
    'mock contains the five phase-one insights and an insufficient item',
    () {
      final insights = getInsightsMock();

      expect(insights, hasLength(6));
      expect(
        insights.map((insight) => insight.tipo),
        containsAll([
          'melhor_horario',
          'duracao_ideal',
          'vies_estimativa',
          'taxa_furo',
          'cramming',
        ]),
      );
      expect(
        insights.where((insight) => insight.confianca == 'insuficiente'),
        hasLength(1),
      );
      expect(
        insights.every((insight) => insight.natureza == 'observacional'),
        isTrue,
      );
    },
  );
}
