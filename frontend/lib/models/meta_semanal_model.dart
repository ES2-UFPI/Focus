class MetaSemanal {
  final String? id;
  final String disciplinaId;
  final String disciplinaNome;
  int cargaHorariaPlanejada; // em minutos
  final int totalRealizado;
  final int minutosRestantes;
  final double percentualConcluido;

  MetaSemanal({
    this.id,
    required this.disciplinaId,
    required this.disciplinaNome,
    required this.cargaHorariaPlanejada,
    this.totalRealizado = 0,
    this.minutosRestantes = 0,
    this.percentualConcluido = 0,
  });

  factory MetaSemanal.fromJson(Map<String, dynamic> json) {
    return MetaSemanal(
      id: json['id']?.toString(),
      disciplinaId: json['disciplina']?.toString() ?? '',
      disciplinaNome: json['disciplina_nome'] ?? '',
      cargaHorariaPlanejada: json['carga_horaria_planejada'] ?? 0,
      totalRealizado: json['total_realizado'] ?? 0,
      minutosRestantes: json['minutos_restantes'] ?? 0,
      percentualConcluido: (json['percentual_concluido'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disciplina': disciplinaId,
      'carga_horaria_planejada': cargaHorariaPlanejada,
    };
  }

  int get horas => cargaHorariaPlanejada ~/ 60;
}