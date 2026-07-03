import '../models/insights_model.dart';

/// Fonte temporária e única dos insights exibidos no painel Insights.
///
/// Quando o endpoint estiver disponível, esta chamada será o ponto de troca
/// pelo método equivalente do serviço de API.
List<Insight> getInsightsMock() {
  return const [
    Insight(
      tipo: 'melhor_horario',
      titulo: 'Seu rendimento tende a ser maior pela manhã',
      descricao:
          'Na mesma disciplina, sua produtividade média é 4,1 pela manhã e '
          '2,4 à noite.',
      numeros: {'manha': 4.1, 'noite': 2.4, 'delta_pct': 41},
      categoria: 'tempo',
      amostra: 18,
      confianca: 'alta',
      natureza: 'observacional',
      severidade: 'positivo',
    ),
    Insight(
      tipo: 'melhor_dia_semana',
      titulo: 'Quinta-feira tende a ser seu dia mais produtivo',
      descricao:
          'Sua produtividade média às quintas é 4,4, enquanto nos outros dias '
          'fica em 3,2.',
      numeros: {
        'produtividade_quinta': 4.4,
        'media_outros_dias': 3.2,
        'delta_pct': 38,
      },
      categoria: 'tempo',
      amostra: 16,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'positivo',
    ),
    Insight(
      tipo: 'duracao_ideal',
      titulo: 'Sua produtividade tende a cair após 50 minutos',
      descricao:
          'Sessões mais longas apresentam uma queda média de 36% na sua '
          'avaliação de produtividade.',
      numeros: {
        'limite_min': 50,
        'antes_limite': 4.2,
        'depois_limite': 2.7,
        'queda_pct': 36,
      },
      categoria: 'foco',
      amostra: 22,
      confianca: 'alta',
      natureza: 'observacional',
      severidade: 'atencao',
    ),
    Insight(
      tipo: 'foco_sem_interrupcoes',
      titulo: 'Blocos sem interrupção aparecem nas suas melhores sessões',
      descricao:
          'Em 72% das sessões avaliadas como produtivas, você não registrou '
          'interrupções durante o bloco principal.',
      numeros: {
        'sessoes_sem_interrupcao_pct': 72,
        'media_blocos_foco_min': 38,
        'interrupcoes_media': 1.2,
      },
      categoria: 'foco',
      amostra: 25,
      confianca: 'alta',
      natureza: 'observacional',
      severidade: 'positivo',
    ),
    Insight(
      tipo: 'vies_estimativa',
      titulo: 'Você costuma subestimar Cálculo em cerca de 40%',
      descricao:
          'As sessões planejadas para 60 minutos terminam, em média, com '
          '84 minutos de duração.',
      numeros: {'estimado_min': 60, 'real_min': 84, 'delta_pct': 40},
      categoria: 'planejamento',
      disciplina: 'Cálculo',
      amostra: 15,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'atencao',
    ),
    Insight(
      tipo: 'tarefas_no_prazo',
      titulo: '78% das suas tarefas recentes foram concluídas no prazo',
      descricao:
          'Você entregou 14 de 18 tarefas até a data planejada nas últimas '
          'seis semanas.',
      numeros: {'concluidas': 14, 'total_tarefas': 18, 'taxa_pct': 78},
      categoria: 'planejamento',
      amostra: 18,
      confianca: 'alta',
      natureza: 'observacional',
      severidade: 'positivo',
    ),
    Insight(
      tipo: 'taxa_furo',
      titulo: '60% das sessões de sexta à noite são canceladas',
      descricao:
          'Esse horário concentra 6 cancelamentos entre as últimas 10 sessões '
          'planejadas.',
      numeros: {'sessoes_sexta_noite': 10, 'canceladas': 6, 'taxa_pct': 60},
      categoria: 'rotina',
      amostra: 10,
      confianca: 'alta',
      natureza: 'observacional',
      severidade: 'critico',
    ),
    Insight(
      tipo: 'sequencia_produtiva',
      titulo: 'Você reuniu 5 sessões produtivas em sequência',
      descricao:
          'A sequência ocorreu com intervalos médios de dois dias e '
          'produtividade média de 4,3.',
      numeros: {
        'sequencia_sessoes': 5,
        'produtividade_media': 4.3,
        'intervalo_medio_dias': 2,
      },
      categoria: 'rotina',
      amostra: 5,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'positivo',
    ),
    Insight(
      tipo: 'cramming',
      titulo: '78% do estudo para provas ocorre nas últimas 48h',
      descricao:
          'Das 9 horas estudadas antes das últimas provas, 7 horas ficaram '
          'concentradas nos dois dias finais.',
      numeros: {
        'horas_totais': 9,
        'horas_ultimas_48h': 7,
        'concentracao_pct': 78,
      },
      categoria: 'planejamento',
      amostra: 8,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'atencao',
    ),
    // PREVIEW MOCK: os dados de sono abaixo são inteiramente simulados.
    // HealthKit/Health Connect e o pacote health pertencem a uma fase futura.
    Insight(
      tipo: 'sono_x_rendimento',
      titulo: 'Você tende a render menos após noites curtas',
      descricao:
          'Nos dias em que dormiu menos de 6h, sua produtividade média foi '
          '2,6, comparada a 4,0 após noites mais longas.',
      numeros: {
        'horas_sono_curto': 6,
        'rendimento_pouco_sono': 2.6,
        'rendimento_bom_sono': 4.0,
        'queda_pct': 35,
      },
      categoria: 'saude',
      amostra: 12,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'atencao',
    ),
    Insight(
      tipo: 'ritmo_disciplina',
      titulo: 'Seu ritmo por disciplina ainda está se formando',
      descricao:
          'Registre mais sessões de uma mesma disciplina para comparar seu '
          'ritmo com segurança.',
      numeros: {'sessoes_registradas': 3, 'minimo_sugerido': 8},
      categoria: 'foco',
      disciplina: 'Física',
      amostra: 3,
      confianca: 'insuficiente',
      natureza: 'observacional',
      severidade: 'info',
    ),
  ];
}
