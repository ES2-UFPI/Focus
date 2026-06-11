class MaterialEstudo {
  final String id;
  final String titulo;
  final String tipo;
  final String? url;
  final String? arquivoPath;
  final String? descricao;
  final String disciplinaId;
  final String disciplinaNome;
  final DateTime dataInsercao;

  const MaterialEstudo({
    required this.id,
    required this.titulo,
    required this.tipo,
    this.url,
    this.arquivoPath,
    this.descricao,
    required this.disciplinaId,
    required this.disciplinaNome,
    required this.dataInsercao,
  });

  factory MaterialEstudo.fromJson(Map<String, dynamic> json) {
    return MaterialEstudo(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      tipo: json['tipo'] as String,
      url: json['url'] as String?,
      arquivoPath: json['arquivo'] as String?,
      descricao: json['descricao'] as String?,
      disciplinaId: json['disciplina'] as String,
      disciplinaNome: json['disciplina_nome'] as String? ?? '',
      dataInsercao: DateTime.parse(json['data_insercao'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'tipo': tipo,
      if (url != null) 'url': url,
      if (arquivoPath != null) 'arquivo': arquivoPath,
      if (descricao != null) 'descricao': descricao,
      'disciplina': disciplinaId,
    };
  }

  MaterialEstudo copyWith({
    String? titulo,
    String? tipo,
    String? url,
    String? arquivoPath,
    String? descricao,
    String? disciplinaId,
    String? disciplinaNome,
  }) {
    return MaterialEstudo(
      id: id,
      titulo: titulo ?? this.titulo,
      tipo: tipo ?? this.tipo,
      url: url ?? this.url,
      arquivoPath: arquivoPath ?? this.arquivoPath,
      descricao: descricao ?? this.descricao,
      disciplinaId: disciplinaId ?? this.disciplinaId,
      disciplinaNome: disciplinaNome ?? this.disciplinaNome,
      dataInsercao: dataInsercao,
    );
  }
}
