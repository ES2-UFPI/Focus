import '../models/insights_model.dart';

// Perfil da demo:
// Estudante do 5º semestre de Engenharia de Software.
// Estagia das 13h às 17h e usa o Focus para manter Estruturas de Dados
// e Banco de Dados sob controle sem empurrar tudo para sexta à noite.
const _estruturasDisciplinaId = '62bca7f0919a4536b5337fcbf3f777c6';
const _bancoDadosDisciplinaId = '3c2a4a0d5fef4e4f937f7f91bba253bb';

/// Fonte temporária e única dos insights exibidos no painel Insights.
///
/// Quando o endpoint estiver disponível, esta chamada será o ponto de troca
/// pelo método equivalente do serviço de API.
List<Insight> getInsightsMock() {
  return const [
    Insight(
      id: 'estudante-melhor-horario',
      tipo: 'melhor_horario',
      titulo: 'Você rende melhor em Estruturas de Dados pela manhã',
      descricao:
          'Nas sessões de Estruturas de Dados, a produtividade média é 4,3 '
          'entre 7h e 10h, contra 2,9 depois das 20h.',
      numeros: {'manha': 4.3, 'noite': 2.9, 'delta_pct': 48},
      categoria: 'tempo',
      disciplina: 'Estruturas de Dados',
      amostra: 12,
      confianca: 'alta',
      natureza: 'observacional',
      severidade: 'positivo',
      grafico: InsightChart(
        tipo: 'barras',
        labels: ['7-10h', '10-13h', '14-17h', '18-20h', '20-22h'],
        valores: [4.3, 3.8, 3.1, 3.0, 2.9],
        destaqueIndex: 0,
      ),
      sessoesEvidencia: [
        InsightEvidenceSession(
          data: '2026-06-18',
          disciplina: 'Estruturas de Dados',
          duracaoMin: 48,
          produtividade: 4.4,
        ),
        InsightEvidenceSession(
          data: '2026-06-23',
          disciplina: 'Estruturas de Dados',
          duracaoMin: 50,
          produtividade: 4.2,
        ),
        InsightEvidenceSession(
          data: '2026-06-26',
          disciplina: 'Estruturas de Dados',
          duracaoMin: 45,
          produtividade: 4.3,
        ),
      ],
      acao: InsightAction(
        tipo: 'agendar_sessao',
        label: 'Agendar ED pela manhã',
        disciplinaId: _estruturasDisciplinaId,
        horarioSugerido: 'manha',
      ),
    ),
    Insight(
      id: 'estudante-duracao-bd',
      tipo: 'duracao_ideal',
      titulo: 'Blocos acima de 50 min cansam em Banco de Dados',
      descricao:
          'Nas revisões de SQL, a produtividade fica perto de 4,0 até 50 '
          'minutos e cai para 2,8 em blocos longos.',
      numeros: {
        'limite_min': 50,
        'antes_limite': 4.0,
        'depois_limite': 2.8,
        'queda_pct': 30,
      },
      categoria: 'foco',
      disciplina: 'Banco de Dados',
      amostra: 10,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'atencao',
      grafico: InsightChart(
        tipo: 'linha',
        labels: ['25 min', '40 min', '50 min', '70 min'],
        valores: [3.7, 4.0, 3.9, 2.8],
        destaqueIndex: 2,
      ),
      sessoesEvidencia: [
        InsightEvidenceSession(
          data: '2026-06-17',
          disciplina: 'Banco de Dados',
          duracaoMin: 42,
          produtividade: 4.1,
        ),
        InsightEvidenceSession(
          data: '2026-06-20',
          disciplina: 'Banco de Dados',
          duracaoMin: 50,
          produtividade: 3.9,
        ),
        InsightEvidenceSession(
          data: '2026-06-25',
          disciplina: 'Banco de Dados',
          duracaoMin: 78,
          produtividade: 2.8,
        ),
      ],
    ),
    Insight(
      id: 'estudante-tarefas-prazo',
      tipo: 'tarefas_no_prazo',
      titulo: 'Você entregou 6 de 8 tarefas no prazo',
      descricao:
          'As entregas recentes estão quase em dia, mas as pendências se '
          'concentram no trabalho prático de Banco de Dados.',
      numeros: {'concluidas': 6, 'total_tarefas': 8, 'taxa_pct': 75},
      categoria: 'planejamento',
      amostra: 8,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'positivo',
    ),
    Insight(
      id: 'estudante-sexta-noite',
      tipo: 'taxa_furo',
      titulo: 'Sexta à noite segue sendo o horário mais frágil',
      descricao:
          'Você cancelou 3 de 5 sessões planejadas para sexta depois das '
          '20h, quase sempre por cansaço acumulado da semana.',
      numeros: {'sessoes_sexta_noite': 5, 'canceladas': 3, 'taxa_pct': 60},
      categoria: 'rotina',
      disciplina: 'Banco de Dados',
      amostra: 5,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'critico',
      grafico: InsightChart(
        tipo: 'barras',
        labels: ['Realizadas', 'Canceladas'],
        valores: [2, 3],
        destaqueIndex: 1,
      ),
      sessoesEvidencia: [
        InsightEvidenceSession(
          data: '2026-06-12',
          disciplina: 'Banco de Dados',
          duracaoMin: 0,
          produtividade: 0,
        ),
        InsightEvidenceSession(
          data: '2026-06-19',
          disciplina: 'Banco de Dados',
          duracaoMin: 0,
          produtividade: 0,
        ),
        InsightEvidenceSession(
          data: '2026-06-26',
          disciplina: 'Banco de Dados',
          duracaoMin: 36,
          produtividade: 3.0,
        ),
      ],
      acao: InsightAction(
        tipo: 'reagendar',
        label: 'Reagendar sexta à noite',
        disciplinaId: _bancoDadosDisciplinaId,
        horarioSugerido: 'manha',
      ),
    ),
    Insight(
      id: 'estudante-desgaste',
      tipo: 'desgaste',
      titulo: 'O cansaço aparece quando você empilha estudo no fim do dia',
      descricao:
          'Nos dias com estágio, sono curto e estudo depois das 20h, a '
          'produtividade média cai 26%.',
      numeros: {'sessoes_noturnas': 4, 'horas_sono_media': 5.8, 'queda_pct': 26},
      categoria: 'saude',
      amostra: 7,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'critico',
    ),
    Insight(
      id: 'estudante-efeito-manha',
      tipo: 'efeito_acao',
      titulo: 'Estudar Estruturas de Dados cedo já melhorou o rendimento',
      descricao:
          'Depois que você antecipou duas sessões para a manhã, a '
          'produtividade média subiu de 3,5 para 4,2.',
      numeros: {
        'ganho_pct': 20,
        'produtividade_antes': 3.5,
        'produtividade_depois': 4.2,
      },
      categoria: 'tempo',
      disciplina: 'Estruturas de Dados',
      amostra: 6,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'positivo',
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
        resumo: 'A janela da manhã virou seu melhor horário.',
        tendencia: '+20% após mover ED para antes do estágio',
        direcao: 'subindo',
        severidade: 'positivo',
        insightTipo: 'efeito_acao',
      ),
      StudyDimension(
        id: 'foco',
        titulo: 'Foco',
        resumo: 'Blocos de até 50 min preservam melhor o ritmo.',
        tendencia: 'Queda de 30% em blocos longos',
        direcao: 'atencao',
        severidade: 'atencao',
        insightTipo: 'duracao_ideal',
      ),
      StudyDimension(
        id: 'planejamento',
        titulo: 'Planejamento',
        resumo: 'As tarefas estão quase em dia.',
        tendencia: '75% das entregas recentes no prazo',
        direcao: 'subindo',
        severidade: 'positivo',
        insightTipo: 'tarefas_no_prazo',
      ),
      StudyDimension(
        id: 'rotina',
        titulo: 'Rotina',
        resumo: 'Sexta à noite ainda derruba o plano semanal.',
        tendencia: '3 de 5 sessões canceladas',
        direcao: 'caindo',
        severidade: 'critico',
        insightTipo: 'taxa_furo',
      ),
      StudyDimension(
        id: 'recuperacao',
        titulo: 'Recuperação',
        resumo: 'Sono curto e estudo tardio aparecem juntos.',
        tendencia: 'Produtividade cai 26% nesses dias',
        direcao: 'caindo',
        severidade: 'critico',
        insightTipo: 'desgaste',
      ),
    ],
    comparacoes: [
      InsightComparison(
        id: 'produtividade-ed',
        titulo: 'Produtividade em ED',
        contexto: 'Depois de antecipar sessões para a manhã',
        antes: 3.5,
        agora: 4.2,
        unidade: '/5',
        variacao: '+20%',
        serie: [3.3, 3.5, 3.7, 4.0, 4.2],
        insightTipo: 'efeito_acao',
      ),
      InsightComparison(
        id: 'cancelamentos-sexta',
        titulo: 'Cancelamentos de sexta',
        contexto: 'Sessões noturnas de Banco de Dados',
        antes: 60,
        agora: 40,
        unidade: '%',
        variacao: '-20%',
        melhoraQuandoDiminui: true,
        serie: [60, 60, 50, 40],
        insightTipo: 'taxa_furo',
      ),
      InsightComparison(
        id: 'tarefas-no-prazo',
        titulo: 'Tarefas no prazo',
        contexto: 'Entregas de ED e Banco de Dados',
        antes: 62,
        agora: 75,
        unidade: '%',
        variacao: '+13%',
        serie: [62, 66, 70, 75],
        insightTipo: 'tarefas_no_prazo',
      ),
    ],
    experimentos: [
      InsightExperiment(
        id: 'ed-manha',
        titulo: 'ED antes do estágio',
        hipotese: 'Resolver exercícios cedo melhora a retenção.',
        disciplina: 'Estruturas de Dados',
        estado: 'resultado',
        inicio: 'Iniciado há 2 semanas',
        metrica: 'Produtividade média',
        valorInicial: 3.5,
        valorAtual: 4.2,
        unidade: '/5',
        variacao: '+20%',
        amostra: 6,
        confianca: 'media',
        insightTipo: 'efeito_acao',
      ),
      InsightExperiment(
        id: 'sexta-sem-noite',
        titulo: 'Banco de Dados fora da sexta à noite',
        hipotese: 'Antecipar a sessão reduz cancelamentos.',
        disciplina: 'Banco de Dados',
        estado: 'testando',
        inicio: 'Em teste há 6 dias',
        metrica: 'Taxa de cancelamento',
        valorInicial: 60,
        valorAtual: 40,
        unidade: '%',
        variacao: '-20%',
        amostra: 5,
        confianca: 'media',
        insightTipo: 'taxa_furo',
      ),
      InsightExperiment(
        id: 'bd-50-min',
        titulo: 'Blocos de 50 min em BD',
        hipotese: 'Encerrar antes da queda preserva energia para revisar SQL.',
        disciplina: 'Banco de Dados',
        estado: 'pronto',
        inicio: 'Pronto para testar',
        metrica: 'Produtividade após 50 min',
        valorInicial: 2.8,
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
          'Você rendia menos depois das 20h: média 2,9 contra 4,3 pela '
          'manhã em Estruturas de Dados.',
      insightTipo: 'melhor_horario',
    ),
    InsightJourneyEvent(
      data: 'Há 2 semanas',
      tipo: 'acao',
      texto:
          'Você passou a reservar dois blocos de ED antes do estágio, entre 7h '
          'e 10h.',
      insightTipo: 'melhor_horario',
    ),
    InsightJourneyEvent(
      data: 'Há 8 dias',
      tipo: 'melhora',
      texto:
          'Ao reduzir as sessões de ED depois das 20h, a produtividade subiu '
          'de 3,5 para 4,2 nas manhãs.',
      insightTipo: 'desgaste',
    ),
    InsightJourneyEvent(
      data: 'Há 6 dias',
      tipo: 'melhora',
      texto:
          'Ao encurtar as revisões de Banco de Dados para 50 min, o fim do '
          'bloco deixou de derrubar tanto o foco.',
      insightTipo: 'duracao_ideal',
    ),
    InsightJourneyEvent(
      data: 'Há 3 dias',
      tipo: 'melhora',
      texto:
          'Ao tirar Banco de Dados da sexta à noite, os cancelamentos caíram '
          'de 60% para 40% na semana.',
      insightTipo: 'taxa_furo',
    ),
    InsightJourneyEvent(
      data: 'Ontem',
      tipo: 'detectado',
      texto:
          'Um novo ponto de atenção apareceu: sessões de Banco de Dados na '
          'sexta à noite continuam sendo canceladas.',
      insightTipo: 'taxa_furo',
    ),
  ];
}
