import '../models/insights_model.dart';

/// Fonte temporária e única dos insights exibidos no Perfil de Estudo.
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
      amostra: 18,
      confianca: 'alta',
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
      amostra: 22,
      confianca: 'alta',
      natureza: 'observacional',
      severidade: 'atencao',
    ),
    Insight(
      tipo: 'vies_estimativa',
      titulo: 'Você costuma subestimar Cálculo em cerca de 40%',
      descricao:
          'As sessões planejadas para 60 minutos terminam, em média, com '
          '84 minutos de duração.',
      numeros: {'estimado_min': 60, 'real_min': 84, 'delta_pct': 40},
      amostra: 15,
      confianca: 'media',
      natureza: 'observacional',
      severidade: 'atencao',
    ),
    Insight(
      tipo: 'taxa_furo',
      titulo: '60% das sessões de sexta à noite são canceladas',
      descricao:
          'Esse horário concentra 6 cancelamentos entre as últimas 10 sessões '
          'planejadas.',
      numeros: {'sessoes_sexta_noite': 10, 'canceladas': 6, 'taxa_pct': 60},
      amostra: 10,
      confianca: 'alta',
      natureza: 'observacional',
      severidade: 'critico',
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
      amostra: 8,
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
      amostra: 3,
      confianca: 'insuficiente',
      natureza: 'observacional',
      severidade: 'info',
    ),
  ];
}
