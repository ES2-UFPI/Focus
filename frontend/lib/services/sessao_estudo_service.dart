import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/network/api_client.dart';
import 'agenda_service.dart';

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
    required String status,          // 🌟 Adicionado
    required int duracaoRealizada,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/sessoes-estudo/');

    final body = {
      'disciplina': disciplinaId,
      'inicio': inicio.toUtc().toIso8601String(),
      'fim': fim.toUtc().toIso8601String(),
      'status': 'AGENDADO',
      'duracao_realizada': duracaoRealizada, // 👈 Agora usa o parâmetro da tela
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
