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

/// Insight observacional sobre os hábitos de estudo do aluno.
///
/// Os nomes dos campos acompanham o contrato previsto para o backend, permitindo
/// que a fonte mock seja substituída sem adaptar os componentes visuais.
class Insight {
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
