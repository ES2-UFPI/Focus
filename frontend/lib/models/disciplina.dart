class Disciplina {
  final String id;
  final String nome;
  final String codigo;
  final String cor;

  const Disciplina({
    required this.id,
    required this.nome,
    required this.codigo,
    required this.cor,
  });

  factory Disciplina.fromJson(Map<String, dynamic> json) {
    return Disciplina(
      id: json['id'] as String,
      nome: json['nome'] as String,
      codigo: json['codigo'] as String? ?? '',
      cor: json['cor'] as String? ?? '#6366f1',
    );
  }
}
