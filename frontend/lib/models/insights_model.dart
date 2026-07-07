/// Próximo passo opcional associado a um insight.
class InsightAction {
  final String tipo;
  final String label;
  final String? disciplinaId;
  final String? horarioSugerido;

  const InsightAction({
    required this.tipo,
    required this.label,
    this.disciplinaId,
    this.horarioSugerido,
  });

  factory InsightAction.fromJson(Map<String, dynamic> json) {
    return InsightAction(
      tipo: json['tipo'] as String? ?? '',
      label: json['label'] as String? ?? '',
      disciplinaId:
          json['disciplina_id'] as String? ?? json['disciplinaId'] as String?,
      horarioSugerido:
          json['horario_sugerido'] as String? ??
          json['horarioSugerido'] as String?,
    );
  }
}

/// Dados necessários para renderizar a evidência visual de um insight.
class InsightChart {
  final String tipo;
  final List<String> labels;
  final List<num> valores;
  final int? destaqueIndex;

  const InsightChart({
    required this.tipo,
    required this.labels,
    required this.valores,
    this.destaqueIndex,
  });

  factory InsightChart.fromJson(Map<String, dynamic> json) {
    final labelsJson = json['labels'];
    final valoresJson = json['valores'];
    final destaqueJson = json['destaqueIndex'] ?? json['destaque_index'];

    return InsightChart(
      tipo: json['tipo'] as String? ?? 'barras',
      labels: labelsJson is List
          ? List<String>.unmodifiable(
              labelsJson.map((label) => label.toString()),
            )
          : const [],
      valores: valoresJson is List
          ? List<num>.unmodifiable(valoresJson.whereType<num>())
          : const [],
      destaqueIndex: destaqueJson is num ? destaqueJson.toInt() : null,
    );
  }
}

/// Sessão representativa usada como evidência observacional de um insight.
class InsightEvidenceSession {
  final String data;
  final String? disciplina;
  final int duracaoMin;
  final num produtividade;

  const InsightEvidenceSession({
    required this.data,
    this.disciplina,
    required this.duracaoMin,
    required this.produtividade,
  });

  factory InsightEvidenceSession.fromJson(Map<String, dynamic> json) {
    final duracaoJson = json['duracaoMin'] ?? json['duracao_min'];

    return InsightEvidenceSession(
      data: json['data'] as String? ?? '',
      disciplina: json['disciplina'] as String?,
      duracaoMin: duracaoJson is num ? duracaoJson.toInt() : 0,
      produtividade: json['produtividade'] as num? ?? 0,
    );
  }
}

/// Marco da jornada diagnóstico → ação → melhora exibida na aba Evolução.
class InsightJourneyEvent {
  final String data;
  final String texto;
  final String tipo;
  final String? insightTipo;

  const InsightJourneyEvent({
    required this.data,
    required this.texto,
    required this.tipo,
    this.insightTipo,
  });

  factory InsightJourneyEvent.fromJson(Map<String, dynamic> json) {
    return InsightJourneyEvent(
      data: json['data'] as String? ?? '',
      texto: json['texto'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'detectado',
      insightTipo:
          json['insight_tipo'] as String? ?? json['insightTipo'] as String?,
    );
  }
}

/// Visão resumida que orienta a leitura dos insights por decisão e evolução.
///
/// O backend futuro pode entregar este bloco junto dos insights para manter a
/// priorização e as comparações determinísticas fora da camada visual.
class InsightsDashboard {
  final String periodo;
  final String atualizadoEm;
  final List<StudyDimension> dimensoes;
  final List<InsightComparison> comparacoes;
  final List<InsightExperiment> experimentos;

  const InsightsDashboard({
    required this.periodo,
    required this.atualizadoEm,
    this.dimensoes = const [],
    this.comparacoes = const [],
    this.experimentos = const [],
  });

  factory InsightsDashboard.fromJson(Map<String, dynamic> json) {
    final dimensoesJson = json['dimensoes'];
    final comparacoesJson = json['comparacoes'];
    final experimentosJson = json['experimentos'];

    return InsightsDashboard(
      periodo: json['periodo'] as String? ?? '',
      atualizadoEm:
          json['atualizado_em'] as String? ??
          json['atualizadoEm'] as String? ??
          '',
      dimensoes: dimensoesJson is List
          ? List<StudyDimension>.unmodifiable(
              dimensoesJson.whereType<Map>().map(
                (item) =>
                    StudyDimension.fromJson(Map<String, dynamic>.from(item)),
              ),
            )
          : const [],
      comparacoes: comparacoesJson is List
          ? List<InsightComparison>.unmodifiable(
              comparacoesJson.whereType<Map>().map(
                (item) =>
                    InsightComparison.fromJson(Map<String, dynamic>.from(item)),
              ),
            )
          : const [],
      experimentos: experimentosJson is List
          ? List<InsightExperiment>.unmodifiable(
              experimentosJson.whereType<Map>().map(
                (item) =>
                    InsightExperiment.fromJson(Map<String, dynamic>.from(item)),
              ),
            )
          : const [],
    );
  }
}

/// Uma dimensão independente da saúde do estudo.
///
/// Não existe pontuação geral: tempo, foco, planejamento, consistência e
/// recuperação são apresentados separadamente para não misturar grandezas.
class StudyDimension {
  final String id;
  final String titulo;
  final String resumo;
  final String tendencia;
  final String direcao;
  final String severidade;
  final String? insightTipo;

  const StudyDimension({
    required this.id,
    required this.titulo,
    required this.resumo,
    required this.tendencia,
    required this.direcao,
    required this.severidade,
    this.insightTipo,
  });

  factory StudyDimension.fromJson(Map<String, dynamic> json) {
    return StudyDimension(
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      resumo: json['resumo'] as String? ?? '',
      tendencia: json['tendencia'] as String? ?? '',
      direcao: json['direcao'] as String? ?? 'estavel',
      severidade: json['severidade'] as String? ?? 'info',
      insightTipo:
          json['insight_tipo'] as String? ?? json['insightTipo'] as String?,
    );
  }
}

/// Comparação temporal usada na leitura "antes × agora".
class InsightComparison {
  final String id;
  final String titulo;
  final String contexto;
  final num antes;
  final num agora;
  final String unidade;
  final String variacao;
  final bool melhoraQuandoDiminui;
  final List<num> serie;
  final String? insightTipo;

  const InsightComparison({
    required this.id,
    required this.titulo,
    required this.contexto,
    required this.antes,
    required this.agora,
    required this.unidade,
    required this.variacao,
    this.melhoraQuandoDiminui = false,
    this.serie = const [],
    this.insightTipo,
  });

  factory InsightComparison.fromJson(Map<String, dynamic> json) {
    final serieJson = json['serie'];

    return InsightComparison(
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      contexto: json['contexto'] as String? ?? '',
      antes: json['antes'] as num? ?? 0,
      agora: json['agora'] as num? ?? 0,
      unidade: json['unidade'] as String? ?? '',
      variacao: json['variacao'] as String? ?? '',
      melhoraQuandoDiminui:
          json['melhora_quando_diminui'] as bool? ??
          json['melhoraQuandoDiminui'] as bool? ??
          false,
      serie: serieJson is List
          ? List<num>.unmodifiable(serieJson.whereType<num>())
          : const [],
      insightTipo:
          json['insight_tipo'] as String? ?? json['insightTipo'] as String?,
    );
  }
}

/// Ciclo observacional de hipótese → ação → resultado.
class InsightExperiment {
  final String id;
  final String titulo;
  final String hipotese;
  final String disciplina;
  final String estado;
  final String inicio;
  final String metrica;
  final num valorInicial;
  final num? valorAtual;
  final String unidade;
  final String variacao;
  final int amostra;
  final String confianca;
  final String? insightTipo;

  const InsightExperiment({
    required this.id,
    required this.titulo,
    required this.hipotese,
    required this.disciplina,
    required this.estado,
    required this.inicio,
    required this.metrica,
    required this.valorInicial,
    this.valorAtual,
    required this.unidade,
    required this.variacao,
    required this.amostra,
    required this.confianca,
    this.insightTipo,
  });

  factory InsightExperiment.fromJson(Map<String, dynamic> json) {
    return InsightExperiment(
      id: json['id'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      hipotese: json['hipotese'] as String? ?? '',
      disciplina: json['disciplina'] as String? ?? '',
      estado: json['estado'] as String? ?? 'pronto',
      inicio: json['inicio'] as String? ?? '',
      metrica: json['metrica'] as String? ?? '',
      valorInicial:
          json['valor_inicial'] as num? ?? json['valorInicial'] as num? ?? 0,
      valorAtual: json['valor_atual'] as num? ?? json['valorAtual'] as num?,
      unidade: json['unidade'] as String? ?? '',
      variacao: json['variacao'] as String? ?? '',
      amostra: (json['amostra'] as num?)?.toInt() ?? 0,
      confianca: json['confianca'] as String? ?? 'insuficiente',
      insightTipo:
          json['insight_tipo'] as String? ?? json['insightTipo'] as String?,
    );
  }
}

/// Insight observacional sobre os hábitos de estudo do aluno.
///
/// Os nomes dos campos acompanham o contrato previsto para o backend, permitindo
/// que a fonte mock seja substituída sem adaptar os componentes visuais.
class Insight {
  /// Identificador estável do insight. Vazio no mock; no contrato do backend
  /// vem preenchido e é usado em `POST /api/insights/{id}/feedback`.
  final String id;
  final String tipo;
  final String titulo;
  final String descricao;
  final Map<String, num> numeros;
  final String categoria;
  final String? disciplina;
  final int amostra;
  final String confianca;
  final String natureza;
  final String severidade;
  final InsightAction? acao;
  final InsightChart? grafico;
  final List<InsightEvidenceSession> sessoesEvidencia;

  const Insight({
    this.id = '',
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.numeros,
    this.categoria = 'tempo',
    this.disciplina,
    required this.amostra,
    required this.confianca,
    required this.natureza,
    required this.severidade,
    this.acao,
    this.grafico,
    this.sessoesEvidencia = const [],
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    final numerosJson = json['numeros'];
    final acaoJson = json['acao'];
    final graficoJson = json['grafico'];
    final sessoesJson = json['sessoesEvidencia'] ?? json['sessoes_evidencia'];

    return Insight(
      id: json['id'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      descricao: json['descricao'] as String? ?? '',
      numeros: numerosJson is Map
          ? Map<String, num>.unmodifiable(
              numerosJson.map(
                (key, value) => MapEntry(key.toString(), value as num),
              ),
            )
          : const {},
      categoria: json['categoria'] as String? ?? 'tempo',
      disciplina: json['disciplina'] as String?,
      amostra: (json['amostra'] as num?)?.toInt() ?? 0,
      confianca: json['confianca'] as String? ?? 'insuficiente',
      natureza: json['natureza'] as String? ?? 'observacional',
      severidade: json['severidade'] as String? ?? 'info',
      acao: acaoJson is Map
          ? InsightAction.fromJson(Map<String, dynamic>.from(acaoJson))
          : null,
      grafico: graficoJson is Map
          ? InsightChart.fromJson(Map<String, dynamic>.from(graficoJson))
          : null,
      sessoesEvidencia: sessoesJson is List
          ? List<InsightEvidenceSession>.unmodifiable(
              sessoesJson.whereType<Map>().map(
                (session) => InsightEvidenceSession.fromJson(
                  Map<String, dynamic>.from(session),
                ),
              ),
            )
          : const [],
    );
  }
}
