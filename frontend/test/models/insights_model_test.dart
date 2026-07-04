import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/data/insight_disciplina_colors.dart';
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
      'acao': {
        'tipo': 'agendar_sessao',
        'label': 'Agendar de manhã',
        'disciplina_id': 'disc-1',
        'horario_sugerido': 'manha',
      },
      'grafico': {
        'tipo': 'barras',
        'labels': ['Manhã', 'Noite'],
        'valores': [4.1, 2.4],
        'destaqueIndex': 0,
      },
      'sessoesEvidencia': [
        {
          'data': '2026-06-18',
          'disciplina': 'Cálculo',
          'duracaoMin': 50,
          'produtividade': 4.1,
        },
      ],
    });

    expect(insight.tipo, 'melhor_horario');
    expect(insight.numeros['manha'], 4.1);
    expect(insight.categoria, 'tempo');
    expect(insight.disciplina, 'Cálculo');
    expect(insight.amostra, 18);
    expect(insight.confianca, 'alta');
    expect(insight.natureza, 'observacional');
    expect(insight.severidade, 'info');
    expect(insight.acao?.tipo, 'agendar_sessao');
    expect(insight.acao?.label, 'Agendar de manhã');
    expect(insight.acao?.disciplinaId, 'disc-1');
    expect(insight.acao?.horarioSugerido, 'manha');
    expect(insight.grafico?.tipo, 'barras');
    expect(insight.grafico?.labels, ['Manhã', 'Noite']);
    expect(insight.grafico?.valores, [4.1, 2.4]);
    expect(insight.grafico?.destaqueIndex, 0);
    expect(insight.sessoesEvidencia, hasLength(1));
    expect(insight.sessoesEvidencia.single.duracaoMin, 50);
    expect(insight.sessoesEvidencia.single.produtividade, 4.1);
  });

  test('Insight.fromJson reads the stable id used by feedback', () {
    final insight = Insight.fromJson({
      'id': 'ins-123',
      'tipo': 'melhor_horario',
      'titulo': 'Título',
      'descricao': 'Descrição',
      'numeros': <String, num>{},
    });

    expect(insight.id, 'ins-123');
  });

  test('Insight.fromJson defaults id to empty when absent', () {
    final insight = Insight.fromJson({
      'tipo': 'melhor_horario',
      'titulo': 'Título',
      'descricao': 'Descrição',
      'numeros': <String, num>{},
    });

    expect(insight.id, '');
  });

  test('Insight.fromJson defaults nullable subject and action', () {
    final insight = Insight.fromJson({
      'tipo': 'teste',
      'titulo': 'Teste',
      'descricao': 'Descrição',
      'numeros': <String, num>{},
    });

    expect(insight.categoria, 'tempo');
    expect(insight.disciplina, isNull);
    expect(insight.acao, isNull);
    expect(insight.grafico, isNull);
    expect(insight.sessoesEvidencia, isEmpty);
  });

  test('Insight.fromJson accepts a null action', () {
    final insight = Insight.fromJson({
      'tipo': 'teste',
      'titulo': 'Teste',
      'descricao': 'Descrição',
      'numeros': <String, num>{},
      'acao': null,
    });

    expect(insight.acao, isNull);
  });

  test('mock covers all categories, sleep preview and insufficient data', () {
    final insights = getInsightsMock();

    expect(insights, hasLength(17));
    expect(insights.map((insight) => insight.categoria).toSet(), {
      'tempo',
      'foco',
      'planejamento',
      'rotina',
      'saude',
      'metodo',
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
        'tela_antes_sessao',
        'equilibrio_metodo',
        'efeito_acao',
        'progresso',
        'desgaste',
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
    expect(sleep.acao, isNull);

    final insufficient = insights.singleWhere(
      (insight) => insight.confianca == 'insuficiente',
    );
    expect(insufficient.acao, isNull);

    final detailedTypes = insights
        .where(
          (insight) =>
              insight.grafico != null && insight.sessoesEvidencia.isNotEmpty,
        )
        .map((insight) => insight.tipo)
        .toSet();
    expect(
      detailedTypes,
      containsAll({
        'melhor_horario',
        'duracao_ideal',
        'vies_estimativa',
        'taxa_furo',
        'cramming',
        'sono_x_rendimento',
        'tela_antes_sessao',
        'equilibrio_metodo',
      }),
    );
  });

  test('mock keeps actions curated and subject colors local', () {
    final insights = getInsightsMock();
    final actionable = insights
        .where((insight) => insight.acao != null)
        .toList();

    expect(actionable, hasLength(6));
    expect(actionable.map((insight) => insight.tipo), {
      'melhor_horario',
      'taxa_furo',
      'cramming',
      'ritmo_disciplina',
      'tela_antes_sessao',
      'equilibrio_metodo',
    });
    expect(
      actionable.every(
        (insight) =>
            insight.acao!.tipo == 'agendar_sessao' ||
            insight.acao!.tipo == 'reagendar' ||
            insight.acao!.tipo == 'silenciar_celular',
      ),
      isTrue,
    );
    expect(
      insights.map((insight) => insight.disciplina).whereType<String>().toSet(),
      containsAll({'Cálculo', 'Banco de Dados', 'ES2', 'Física'}),
    );
    expect(insightDisciplinaCoresLocais.keys, containsAll({'Cálculo', 'ES2'}));
  });

  test('journey mock connects detection, action and observed improvement', () {
    final journey = getJornadaMock();

    expect(journey, hasLength(4));
    expect(journey.map((event) => event.tipo).toSet(), {
      'detectado',
      'acao',
      'melhora',
    });
    expect(
      journey.map((event) => event.insightTipo),
      containsAll({'taxa_furo', 'efeito_acao', 'progresso'}),
    );
  });
}
