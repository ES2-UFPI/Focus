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
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    final numerosJson = json['numeros'];
    final acaoJson = json['acao'];

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
    );
  }
}
