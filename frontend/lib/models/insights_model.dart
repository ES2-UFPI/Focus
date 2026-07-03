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
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    final numerosJson = json['numeros'];

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
    );
  }
}
