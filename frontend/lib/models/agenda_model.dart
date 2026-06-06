/// Modelos de dados para o endpoint unificado GET /api/agenda/.
///
/// A API retorna uma lista heterogênea de itens (EVENTO_ACADEMICO e
/// SESSAO_ESTUDO) e uma lista de recomendações de estudo.  Optamos por um
/// modelo único [AgendaItem] com campos opcionais por tipo, mantendo a
/// implementação simples e direta.
library;

// ---------------------------------------------------------------------------
// AgendaItem
// ---------------------------------------------------------------------------

class AgendaItem {
  /// Discriminador de tipo: `'EVENTO_ACADEMICO'` ou `'SESSAO_ESTUDO'`.
  final String tipo;
  final String id;
  final String titulo;

  /// Data no formato `YYYY-MM-DD` — usada para agrupar itens por dia.
  final String data;

  /// Timestamp ISO-8601 completo — usado para ordenação cronológica.
  final DateTime timestamp;

  final String? descricao;
  final String disciplinaNome;

  // -- Campos exclusivos de EVENTO_ACADEMICO (nullable) ---------------------

  /// Ex.: `PROVA`, `TRABALHO`, `SEMINARIO`, `APRESENTACAO`, `OUTRO`.
  final String? tipoEvento;

  /// Ex.: `ATRASADO`, `ALTA`, `MEDIA`, `BAIXA`.
  final String? urgencia;

  final int? diasRestantes;
  final bool? concluido;

  // -- Campos exclusivos de SESSAO_ESTUDO (nullable) ------------------------

  final DateTime? inicio;
  final DateTime? fim;

  /// Ex.: `AGENDADO`, `EM_ANDAMENTO`, `CONCLUIDO`, `CANCELADO`.
  final String? status;

  /// Duração realizada em minutos.
  final int? duracaoRealizada;

  AgendaItem({
    required this.tipo,
    required this.id,
    required this.titulo,
    required this.data,
    required this.timestamp,
    this.descricao,
    required this.disciplinaNome,
    this.tipoEvento,
    this.urgencia,
    this.diasRestantes,
    this.concluido,
    this.inicio,
    this.fim,
    this.status,
    this.duracaoRealizada,
  });

  /// Fábrica de deserialização a partir do JSON retornado pela API.
  factory AgendaItem.fromJson(Map<String, dynamic> json) {
    return AgendaItem(
      tipo: json['tipo'] as String,
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      data: json['data'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      descricao: json['descricao'] as String?,
      disciplinaNome: json['disciplina_nome'] as String? ?? '',
      tipoEvento: json['tipo_evento'] as String?,
      urgencia: json['urgencia'] as String?,
      diasRestantes: json['dias_restantes'] as int?,
      concluido: json['concluido'] as bool?,
      inicio: json['inicio'] != null
          ? DateTime.parse(json['inicio'] as String)
          : null,
      fim: json['fim'] != null
          ? DateTime.parse(json['fim'] as String)
          : null,
      status: json['status'] as String?,
      duracaoRealizada: json['duracao_realizada'] as int?,
    );
  }

  // -- Helpers de conveniência -----------------------------------------------

  bool get isEvento => tipo == 'EVENTO_ACADEMICO';
  bool get isSessao => tipo == 'SESSAO_ESTUDO';
}

// ---------------------------------------------------------------------------
// AgendaRecomendacao
// ---------------------------------------------------------------------------

class AgendaRecomendacao {
  final String eventoId;
  final String eventoTitulo;
  final String recomendacao;

  AgendaRecomendacao({
    required this.eventoId,
    required this.eventoTitulo,
    required this.recomendacao,
  });

  factory AgendaRecomendacao.fromJson(Map<String, dynamic> json) {
    return AgendaRecomendacao(
      eventoId: json['evento_id'] as String,
      eventoTitulo: json['evento_titulo'] as String,
      recomendacao: json['recomendacao'] as String,
    );
  }
}

// ---------------------------------------------------------------------------
// AgendaResponse  (envelope raiz)
// ---------------------------------------------------------------------------

class AgendaResponse {
  final List<AgendaItem> itens;
  final List<AgendaRecomendacao> recomendacoes;

  AgendaResponse({
    required this.itens,
    required this.recomendacoes,
  });

  factory AgendaResponse.fromJson(Map<String, dynamic> json) {
    return AgendaResponse(
      itens: (json['itens'] as List<dynamic>)
          .map((i) => AgendaItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      recomendacoes: (json['recomendacoes'] as List<dynamic>)
          .map((r) => AgendaRecomendacao.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
