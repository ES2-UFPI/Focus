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
      'categoria': 'tempo',
      'disciplina': 'Cálculo',
      'amostra': 18,
      'confianca': 'alta',
      'natureza': 'observacional',
      'severidade': 'info',
    });

    expect(insight.tipo, 'melhor_horario');
    expect(insight.numeros['manha'], 4.1);
    expect(insight.categoria, 'tempo');
    expect(insight.disciplina, 'Cálculo');
    expect(insight.amostra, 18);
    expect(insight.confianca, 'alta');
    expect(insight.natureza, 'observacional');
    expect(insight.severidade, 'info');
  });

  test('Insight.fromJson defaults category and nullable subject', () {
    final insight = Insight.fromJson({
      'tipo': 'teste',
      'titulo': 'Teste',
      'descricao': 'Descrição',
      'numeros': <String, num>{},
    });

    expect(insight.categoria, 'tempo');
    expect(insight.disciplina, isNull);
  });

  test('mock covers all categories, sleep preview and insufficient data', () {
    final insights = getInsightsMock();

    expect(insights, hasLength(11));
    expect(insights.map((insight) => insight.categoria).toSet(), {
      'tempo',
      'foco',
      'planejamento',
      'rotina',
      'saude',
    });
    expect(
      insights.map((insight) => insight.tipo),
      containsAll([
        'melhor_horario',
        'melhor_dia_semana',
        'duracao_ideal',
        'foco_sem_interrupcoes',
        'vies_estimativa',
        'tarefas_no_prazo',
        'taxa_furo',
        'sequencia_produtiva',
        'cramming',
        'sono_x_rendimento',
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

    final sleep = insights.singleWhere(
      (insight) => insight.tipo == 'sono_x_rendimento',
    );
    expect(sleep.categoria, 'saude');
    expect(sleep.numeros['queda_pct'], 35);
  });
}
