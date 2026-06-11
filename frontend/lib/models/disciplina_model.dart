/// Modelo que representa uma Disciplina do backend Django.
class Disciplina {
  final String id;
  final String aluno;
  final String nome;
  final String? codigo;
  final String? descricao;
  final String cor;
  final double metaHorasSemanais;
  final bool ativo;

  Disciplina({
    required this.id,
    required this.aluno,
    required this.nome,
    this.codigo,
    this.descricao,
    this.cor = '#2196F3',
    this.metaHorasSemanais = 0.0,
    this.ativo = true,
  });

  factory Disciplina.fromJson(Map<String, dynamic> json) {
    return Disciplina(
      id: json['id'] as String,
      aluno: json['aluno'] as String,
      nome: json['nome'] as String,
      codigo: json['codigo'] as String?,
      descricao: json['descricao'] as String?,
      cor: json['cor'] as String? ?? '#2196F3',
      metaHorasSemanais: double.tryParse(json['meta_horas_semanais']?.toString() ?? '0') ?? 0.0,
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aluno': aluno,
      'nome': nome,
      'codigo': codigo,
      'descricao': descricao,
      'cor': cor,
      'meta_horas_semanais': metaHorasSemanais,
      'ativo': ativo,
    };
  }
}
