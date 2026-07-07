import '../models/insights_model.dart';

// IDs das disciplinas da massa de demonstração local. No contrato futuro,
// esses valores virão em `acao.disciplina_id`.
const _calculoDisciplinaId = '62bca7f0919a4536b5337fcbf3f777c6';
const _es2DisciplinaId = '3c2a4a0d5fef4e4f937f7f91bba253bb';

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
      disciplina: 'ES2',
      amostra: 18,
      confianca: 'alta',
      natureza: 'observacional',
      severidade: 'positivo',
      grafico: InsightChart(
        tipo: 'barras',
        labels: ['6-9h', '9-12h', '12-15h', '15-18h', '18-21h', '21-0h'],
        valores: [4.1, 4.2, 3.0, 2.8, 2.6, 2.4],
        destaqueIndex: 1,
      ),
      sessoesEvidencia: [
        InsightEvidenceSession(
          data: '2026-06-18',
          disciplina: 'ES2',
          duracaoMin: 48,
          produtividade: 4.3,
        ),
        InsightEvidenceSession(
          data: '2026-06-23',
          disciplina: 'ES2',
          duracaoMin: 52,
          produtividade: 4.1,
        ),
        InsightEvidenceSession(
          data: '2026-06-26',
          disciplina: 'ES2',
          duracaoMin: 45,
          produtividade: 4.2,
        ),
      ],
      acao: InsightAction(
        tipo: 'agendar_sessao',
        label: 'Agendar de manhã',
        disciplinaId: _es2DisciplinaId,
        horarioSugerido: 'manha',
      ),
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
      disciplina: 'Banco de Dados',
      amostra: 22,
      confianca: 'alta',
      natureza: 'observacional',
      severidade: 'atencao',
      grafico: InsightChart(
        tipo: 'linha',
        labels: ['25 min', '40 min', '50 min', '70 min', '90 min'],
        valores: [3.8, 4.2, 4.1, 3.3, 2.7],
        destaqueIndex: 2,
      ),
      sessoesEvidencia: [
        InsightEvidenceSession(
          data: '2026-06-17',
          disciplina: 'Banco de Dados',
          duracaoMin: 42,
          produtividade: 4.4,
        ),
        InsightEvidenceSession(
          data: '2026-06-20',
          disciplina: 'Banco de Dados',
          duracaoMin: 51,
          produtividade: 4.0,
        ),
        InsightEvidenceSession(
          data: '2026-06-25',
          disciplina: 'Banco de Dados',
          duracaoMin: 82,
          produtividade: 2.6,
        ),
      ],
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
      disciplina: 'ES2',
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
      grafico: InsightChart(
        tipo: 'comparacao',
        labels: ['Planejado', 'Realizado'],
        valores: [60, 84],
        destaqueIndex: 1,
      ),
      sessoesEvidencia: [
        InsightEvidenceSession(
          data: '2026-06-16',
          disciplina: 'Cálculo',
          duracaoMin: 87,
          produtividade: 3.8,
        ),
        InsightEvidenceSession(
          data: '2026-06-21',
          disciplina: 'Cálculo',
          duracaoMin: 81,
          produtividade: 4.0,
        ),
        InsightEvidenceSession(
          data: '2026-06-27',
          disciplina: 'Cálculo',
          duracaoMin: 84,
          produtividade: 3.7,
        ),
      ],
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
      disciplina: 'ES2',
      amostra: 10,
      confianca: 'alta',
      natureza: 'observacional',
      severidade: 'critico',
      grafico: InsightChart(
        tipo: 'barras',
        labels: ['Realizadas', 'Canceladas'],
        valores: [4, 6],
        destaqueIndex: 1,
      ),
      sessoesEvidencia: [
        InsightEvidenceSession(
          data: '2026-06-12',
          disciplina: 'ES2',
          duracaoMin: 0,
          produtividade: 0,
        ),
        InsightEvidenceSession(
          data: '2026-06-19',
          disciplina: 'ES2',
          duracaoMin: 0,
          produtividade: 0,
        ),
        InsightEvidenceSession(
          data: '2026-06-26',
          disciplina: 'ES2',
          duracaoMin: 36,
          produtividade: 3.2,
        ),
      ],
      acao: InsightAction(
        tipo: 'reagendar',
        label: 'Reagendar sexta à noite',
        disciplinaId: _es2DisciplinaId,
        horarioSugerido: 'noite',
      ),
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
      disciplina: 'Cálculo',
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
      disciplina: 'Cálculo',
      amostra: 8,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'atencao',
      grafico: InsightChart(
        tipo: 'comparacao',
        labels: ['Antes de 48h', 'Últimas 48h'],
        valores: [2, 7],
        destaqueIndex: 1,
      ),
      sessoesEvidencia: [
        InsightEvidenceSession(
          data: '2026-06-08',
          disciplina: 'Cálculo',
          duracaoMin: 35,
          produtividade: 3.6,
        ),
        InsightEvidenceSession(
          data: '2026-06-09',
          disciplina: 'Cálculo',
          duracaoMin: 95,
          produtividade: 3.1,
        ),
        InsightEvidenceSession(
          data: '2026-06-10',
          disciplina: 'Cálculo',
          duracaoMin: 112,
          produtividade: 2.8,
        ),
      ],
      acao: InsightAction(
        tipo: 'agendar_sessao',
        label: 'Antecipar estudo antes da prova',
        disciplinaId: _calculoDisciplinaId,
      ),
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
      grafico: InsightChart(
        tipo: 'comparacao',
        labels: ['< 6h sono', '≥ 7h sono'],
        valores: [2.6, 4.0],
        destaqueIndex: 0,
      ),
      sessoesEvidencia: [
        InsightEvidenceSession(
          data: '2026-06-15',
          disciplina: 'ES2',
          duracaoMin: 50,
          produtividade: 2.5,
        ),
        InsightEvidenceSession(
          data: '2026-06-22',
          disciplina: 'Cálculo',
          duracaoMin: 47,
          produtividade: 2.7,
        ),
        InsightEvidenceSession(
          data: '2026-06-24',
          disciplina: 'ES2',
          duracaoMin: 55,
          produtividade: 4.0,
        ),
      ],
    ),
    Insight(
      tipo: 'ritmo_disciplina',
      titulo: 'ES2 recebeu menos atenção nas últimas semanas',
      descricao:
          'Seu ritmo recente ficou abaixo das duas sessões semanais que você '
          'costuma manter nessa disciplina.',
      numeros: {'sessoes_registradas': 2, 'minimo_sugerido': 4},
      categoria: 'rotina',
      disciplina: 'ES2',
      amostra: 9,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'atencao',
      acao: InsightAction(
        tipo: 'agendar_sessao',
        label: 'Agendar mais sessões de ES2',
        disciplinaId: _es2DisciplinaId,
      ),
    ),
    // PREVIEW MOCK: a captura real de uso de apps seria Android-only via
    // UsageStatsManager e dependeria de permissão explícita do usuário.
    Insight(
      tipo: 'tela_antes_sessao',
      titulo:
          'Muito tempo de tela aparece antes das sessões mais interrompidas',
      descricao:
          'Sessões iniciadas após mais de 1h em redes sociais tiveram, em '
          'média, o dobro de pausas e nota de foco menor.',
      numeros: {
        'tempo_tela_min': 68,
        'aumento_pausas_pct': 100,
        'foco_apos_tela': 2.5,
      },
      categoria: 'saude',
      amostra: 14,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'atencao',
      grafico: InsightChart(
        tipo: 'comparacao',
        labels: ['Uso habitual', '> 1h de tela'],
        valores: [1.3, 2.6],
        destaqueIndex: 1,
      ),
      sessoesEvidencia: [
        InsightEvidenceSession(
          data: '2026-06-19',
          disciplina: 'ES2',
          duracaoMin: 44,
          produtividade: 2.4,
        ),
        InsightEvidenceSession(
          data: '2026-06-21',
          disciplina: 'Cálculo',
          duracaoMin: 39,
          produtividade: 2.6,
        ),
        InsightEvidenceSession(
          data: '2026-06-28',
          disciplina: 'ES2',
          duracaoMin: 46,
          produtividade: 2.5,
        ),
      ],
      acao: InsightAction(
        tipo: 'silenciar_celular',
        label: 'Silenciar o celular 15 min antes',
      ),
    ),
    Insight(
      tipo: 'equilibrio_metodo',
      titulo: 'Seu estudo está concentrado em leitura',
      descricao:
          'Você dedicou 85% do tempo à leitura e 15% a questões. Perto da '
          'prova, experimente dar mais espaço à prática.',
      numeros: {'leitura_pct': 85, 'questoes_pct': 15},
      categoria: 'metodo',
      disciplina: 'Cálculo',
      amostra: 20,
      confianca: 'alta',
      natureza: 'observacional',
      severidade: 'atencao',
      grafico: InsightChart(
        tipo: 'barras',
        labels: ['Leitura', 'Questões'],
        valores: [85, 15],
        destaqueIndex: 0,
      ),
      sessoesEvidencia: [
        InsightEvidenceSession(
          data: '2026-06-18',
          disciplina: 'Cálculo',
          duracaoMin: 60,
          produtividade: 3.5,
        ),
        InsightEvidenceSession(
          data: '2026-06-23',
          disciplina: 'Cálculo',
          duracaoMin: 72,
          produtividade: 3.3,
        ),
        InsightEvidenceSession(
          data: '2026-06-29',
          disciplina: 'Cálculo',
          duracaoMin: 54,
          produtividade: 3.7,
        ),
      ],
      acao: InsightAction(
        tipo: 'agendar_sessao',
        label: 'Agendar sessão de exercícios',
        disciplinaId: _calculoDisciplinaId,
      ),
    ),
    Insight(
      tipo: 'efeito_acao',
      titulo: 'Seu rendimento melhorou após a mudança de horário',
      descricao:
          'Desde que você passou a estudar ES2 pela manhã, observamos uma '
          'produtividade média 18% maior.',
      numeros: {
        'ganho_pct': 18,
        'produtividade_antes': 3.4,
        'produtividade_depois': 4.0,
      },
      categoria: 'tempo',
      disciplina: 'ES2',
      amostra: 11,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'positivo',
    ),
    Insight(
      tipo: 'progresso',
      titulo: 'Seus cancelamentos de sexta à noite diminuíram',
      descricao:
          'Há duas semanas, 60% dessas sessões eram canceladas; nos registros '
          'mais recentes, a taxa observada ficou em 10%.',
      numeros: {
        'taxa_anterior_pct': 60,
        'taxa_atual_pct': 10,
        'reducao_pct': 83,
      },
      categoria: 'rotina',
      disciplina: 'ES2',
      amostra: 10,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'positivo',
    ),
    Insight(
      tipo: 'desgaste',
      titulo: 'Seus registros recentes mostram sinais de cansaço',
      descricao:
          'Sessões longas em sequência, sono curto e produtividade caindo '
          'apareceram juntos. Considere uma pausa para se recuperar.',
      numeros: {'sessoes_longas': 4, 'horas_sono_media': 5.5, 'queda_pct': 24},
      categoria: 'saude',
      amostra: 9,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'critico',
    ),
    Insight(
      tipo: 'amostra_insuficiente',
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

/// Resumo mockado usado nas leituras de panorama, comparação e experimento.
InsightsDashboard getInsightsDashboardMock() {
  return const InsightsDashboard(
    periodo: '24 a 30 de junho',
    atualizadoEm: 'Atualizado hoje, 08:40',
    dimensoes: [
      StudyDimension(
        id: 'tempo',
        titulo: 'Tempo',
        resumo: 'Seu melhor período está ficando mais claro.',
        tendencia: '+18% após mudar ES2 para a manhã',
        direcao: 'subindo',
        severidade: 'positivo',
        insightTipo: 'efeito_acao',
      ),
      StudyDimension(
        id: 'foco',
        titulo: 'Foco',
        resumo: 'Blocos de até 50 min preservam melhor seu ritmo.',
        tendencia: 'Queda de 36% após esse limite',
        direcao: 'atencao',
        severidade: 'atencao',
        insightTipo: 'duracao_ideal',
      ),
      StudyDimension(
        id: 'planejamento',
        titulo: 'Planejamento',
        resumo: 'As estimativas de Cálculo ainda estão apertadas.',
        tendencia: '+40% de tempo além do planejado',
        direcao: 'atencao',
        severidade: 'atencao',
        insightTipo: 'vies_estimativa',
      ),
      StudyDimension(
        id: 'consistencia',
        titulo: 'Consistência',
        resumo: 'Você está faltando menos às sessões críticas.',
        tendencia: 'Cancelamentos caíram de 60% para 10%',
        direcao: 'subindo',
        severidade: 'positivo',
        insightTipo: 'progresso',
      ),
      StudyDimension(
        id: 'recuperacao',
        titulo: 'Recuperação',
        resumo: 'Sono curto e sessões longas apareceram juntos.',
        tendencia: 'Produtividade recente caiu 24%',
        direcao: 'caindo',
        severidade: 'critico',
        insightTipo: 'desgaste',
      ),
    ],
    comparacoes: [
      InsightComparison(
        id: 'produtividade-es2',
        titulo: 'Produtividade em ES2',
        contexto: 'Depois de mover sessões para a manhã',
        antes: 3.4,
        agora: 4.0,
        unidade: '/5',
        variacao: '+18%',
        serie: [3.2, 3.4, 3.5, 3.7, 4.0],
        insightTipo: 'efeito_acao',
      ),
      InsightComparison(
        id: 'cancelamentos-sexta',
        titulo: 'Cancelamentos na sexta',
        contexto: 'Sessões de ES2 no período da noite',
        antes: 60,
        agora: 10,
        unidade: '%',
        variacao: '-50 p.p.',
        melhoraQuandoDiminui: true,
        serie: [60, 52, 43, 25, 10],
        insightTipo: 'progresso',
      ),
      InsightComparison(
        id: 'tarefas-no-prazo',
        titulo: 'Tarefas no prazo',
        contexto: 'Todas as matérias nas últimas semanas',
        antes: 65,
        agora: 78,
        unidade: '%',
        variacao: '+13 p.p.',
        serie: [65, 68, 70, 74, 78],
        insightTipo: 'tarefas_no_prazo',
      ),
    ],
    experimentos: [
      InsightExperiment(
        id: 'es2-manha',
        titulo: 'ES2 pela manhã',
        hipotese: 'Mover tarefas exigentes para a manhã melhora o rendimento.',
        disciplina: 'ES2',
        estado: 'resultado',
        inicio: 'Iniciado há 2 semanas',
        metrica: 'Produtividade média',
        valorInicial: 3.4,
        valorAtual: 4.0,
        unidade: '/5',
        variacao: '+18%',
        amostra: 11,
        confianca: 'media',
        insightTipo: 'efeito_acao',
      ),
      InsightExperiment(
        id: 'sexta-es2',
        titulo: 'Novo horário para sexta',
        hipotese: 'Antecipar a sessão reduz os cancelamentos de sexta.',
        disciplina: 'ES2',
        estado: 'testando',
        inicio: 'Em teste há 8 dias',
        metrica: 'Taxa de cancelamento',
        valorInicial: 60,
        valorAtual: 10,
        unidade: '%',
        variacao: '-50 p.p.',
        amostra: 10,
        confianca: 'media',
        insightTipo: 'progresso',
      ),
      InsightExperiment(
        id: 'blocos-bd',
        titulo: 'Blocos de até 50 minutos',
        hipotese: 'Encerrar o bloco antes da queda preserva a produtividade.',
        disciplina: 'Banco de Dados',
        estado: 'pronto',
        inicio: 'Pronto para testar',
        metrica: 'Produtividade após 50 min',
        valorInicial: 2.7,
        unidade: '/5',
        variacao: 'Aguardando resultado',
        amostra: 0,
        confianca: 'insuficiente',
        insightTipo: 'duracao_ideal',
      ),
    ],
  );
}

/// Jornada mockada da demo. Na fase de dados, estes eventos virão do backend
/// junto dos insights de progresso e efeito observado após uma ação.
List<InsightJourneyEvent> getJornadaMock() {
  return const [
    InsightJourneyEvent(
      data: 'Há 3 semanas',
      tipo: 'detectado',
      texto:
          'Você rendia bem menos à noite: produtividade média 2,4 contra 4,0 '
          'pela manhã, na mesma disciplina.',
      insightTipo: 'melhor_horario',
    ),
    InsightJourneyEvent(
      data: 'Há 2 semanas',
      tipo: 'acao',
      texto: 'Você aceitou a recomendação e passou a agendar ES2 pela manhã.',
      insightTipo: 'melhor_horario',
    ),
    InsightJourneyEvent(
      data: 'Há 8 dias',
      tipo: 'melhora',
      texto:
          'Nas sessões que você moveu, a produtividade subiu de 2,4 para 3,9 — '
          'observado nas suas próprias sessões.',
      insightTipo: 'efeito_acao',
    ),
    InsightJourneyEvent(
      data: 'Há 3 dias',
      tipo: 'melhora',
      texto:
          'O ganho se manteve pela semana toda: +18% de produtividade média e '
          'nenhuma dessas sessões foi cancelada.',
      insightTipo: 'progresso',
    ),
    InsightJourneyEvent(
      data: 'Ontem',
      tipo: 'detectado',
      texto:
          'Um novo padrão já apareceu pra cuidar: 60% das sessões de sexta à '
          'noite vêm sendo canceladas.',
      insightTipo: 'taxa_furo',
    ),
  ];
}
