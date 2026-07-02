import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/network/api_client.dart';
import 'agenda_service.dart';

/// Resumo de uma sessao de estudo, usado para os cards de progresso do Pomodoro
/// (histórico, horas por dia da semana, sessões concluídas hoje).
class SessaoEstudoResumo {
  final String id;
  final String disciplinaId;
  final String disciplinaNome;
  final String? eventoAcademicoId;
  final DateTime inicio;
  final DateTime fim;
  final int duracaoRealizada;
  final String status;

  SessaoEstudoResumo({
    required this.id,
    required this.disciplinaId,
    required this.disciplinaNome,
    this.eventoAcademicoId,
    required this.inicio,
    required this.fim,
    required this.duracaoRealizada,
    required this.status,
  });

  factory SessaoEstudoResumo.fromJson(Map<String, dynamic> json) {
    return SessaoEstudoResumo(
      id: json['id'] as String,
      disciplinaId: json['disciplina'] as String,
      disciplinaNome: json['disciplina_nome'] as String? ?? '',
      eventoAcademicoId: json['evento_academico'] as String?,
      inicio: DateTime.parse(json['inicio'] as String),
      fim: DateTime.parse(json['fim'] as String),
      duracaoRealizada: json['duracao_realizada'] as int? ?? 0,
      status: json['status'] as String? ?? 'AGENDADO',
    );
  }
}

class SessaoEstudoService {
  static String _extrairMensagemErro(String responseBody) {
    try {
      final decoded = json.decode(responseBody);
      final erros = <String>[];

      if (decoded is Map) {
        decoded.forEach((key, value) {
          if (value is List) {
            erros.addAll(value.map((e) => e.toString()));
          } else {
            erros.add(value.toString());
          }
        });
      } else if (decoded is List) {
        erros.addAll(decoded.map((e) => e.toString()));
      }

      return erros.isNotEmpty ? erros.join('\n') : 'Dados invalidos.';
    } catch (_) {
      return 'Erro inesperado do servidor.';
    }
  }

  /// Cadastra uma nova sessao de estudo no backend.
  Future<void> criarSessao({
    required String disciplinaId,
    required DateTime inicio,
    required DateTime fim,
    String? descricao,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/sessoes-estudo/');

    final body = {
      'disciplina': disciplinaId,
      'inicio': inicio.toUtc().toIso8601String(),
      'fim': fim.toUtc().toIso8601String(),
      'status': 'AGENDADO',
      'duracao_realizada': 0,
      'descricao': descricao,
    };

    try {
      final response = await http.post(
        uri,
        headers: defaultHeaders,
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return;
      }

      throw AgendaServiceException(_extrairMensagemErro(response.body));
    } catch (e) {
      if (e is AgendaServiceException) rethrow;
      throw AgendaServiceException('Erro ao conectar ao servidor: $e');
    }
  }

  /// Atualiza (PATCH) uma sessao de estudo no backend.
  Future<void> editarSessao({
    required String sessaoId,
    required String disciplinaId,
    required DateTime inicio,
    required DateTime fim,
    String? descricao,
    required String status,
    required int duracaoRealizada,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/sessoes-estudo/$sessaoId/');

    final body = {
      'disciplina': disciplinaId,
      'inicio': inicio.toUtc().toIso8601String(),
      'fim': fim.toUtc().toIso8601String(),
      'status': status,
      'duracao_realizada': duracaoRealizada,
      'descricao': descricao,
    };

    try {
      final response = await http.patch(
        uri,
        headers: defaultHeaders,
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }

      throw AgendaServiceException(_extrairMensagemErro(response.body));
    } catch (e) {
      if (e is AgendaServiceException) rethrow;
      throw AgendaServiceException('Erro ao conectar ao servidor: $e');
    }
  }

  /// Cadastra uma sessao de estudo ja concluida no backend (usado pelo Pomodoro
  /// ao final de cada ciclo de foco, evitando o par criar+editar).
  Future<void> criarSessaoConcluida({
    required String disciplinaId,
    required DateTime inicio,
    required DateTime fim,
    required int duracaoRealizada,
    String? descricao,
    String? eventoAcademicoId,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/sessoes-estudo/');

    final body = {
      'disciplina': disciplinaId,
      'inicio': inicio.toUtc().toIso8601String(),
      'fim': fim.toUtc().toIso8601String(),
      'status': 'CONCLUIDO',
      'duracao_realizada': duracaoRealizada,
      'descricao': descricao,
      'evento_academico': eventoAcademicoId,
    };

    try {
      final response = await http.post(
        uri,
        headers: defaultHeaders,
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return;
      }

      throw AgendaServiceException(_extrairMensagemErro(response.body));
    } catch (e) {
      if (e is AgendaServiceException) rethrow;
      throw AgendaServiceException('Erro ao conectar ao servidor: $e');
    }
  }

  /// Busca as sessoes de estudo da semana atual (usado pelo Pomodoro para
  /// horas por dia, sessoes concluidas hoje e historico).
  Future<List<SessaoEstudoResumo>> getSemanaAtual() async {
    final uri = Uri.parse('$kBaseUrl/api/sessoes-estudo/semana_atual/');

    try {
      final response = await http.get(uri, headers: defaultHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>;
        return results
            .map((e) => SessaoEstudoResumo.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw AgendaServiceException(_extrairMensagemErro(response.body));
    } catch (e) {
      if (e is AgendaServiceException) rethrow;
      throw AgendaServiceException('Erro ao conectar ao servidor: $e');
    }
  }

  /// Exclui uma sessao de estudo no backend.
  Future<void> excluirSessao(String sessaoId) async {
    final uri = Uri.parse('$kBaseUrl/api/sessoes-estudo/$sessaoId/');

    try {
      final response = await http.delete(
        uri,
        headers: defaultHeaders,
      );

      if (response.statusCode == 204) {
        return;
      }

      throw AgendaServiceException(_extrairMensagemErro(response.body));
    } catch (e) {
      if (e is AgendaServiceException) rethrow;
      throw AgendaServiceException('Erro ao conectar ao servidor: $e');
    }
  }
}
