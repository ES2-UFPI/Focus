import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import 'agenda_service.dart';

class SessaoEstudoService {
  /// Cadastra uma nova sessão de estudo no backend.
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
        headers: kDefaultHeaders,
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return;
      }

      // Tenta extrair a mensagem de erro detalhada retornada pelo Django
      final Map<String, dynamic> errorData = json.decode(response.body) as Map<String, dynamic>;
      
      final List<String> erros = [];
      errorData.forEach((key, value) {
        if (value is List) {
          erros.addAll(value.map((e) => e.toString()));
        } else {
          erros.add(value.toString());
        }
      });

      throw AgendaServiceException(erros.isNotEmpty ? erros.join('\n') : 'Dados inválidos.');
    } catch (e) {
      if (e is AgendaServiceException) rethrow;
      throw AgendaServiceException('Erro ao conectar ao servidor: $e');
    }
  }

  /// Atualiza (PATCH) uma sessão de estudo no backend.
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
        headers: kDefaultHeaders,
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }

      final Map<String, dynamic> errorData = json.decode(response.body) as Map<String, dynamic>;
      
      final List<String> erros = [];
      errorData.forEach((key, value) {
        if (value is List) {
          erros.addAll(value.map((e) => e.toString()));
        } else {
          erros.add(value.toString());
        }
      });

      throw AgendaServiceException(erros.isNotEmpty ? erros.join('\n') : 'Dados inválidos.');
    } catch (e) {
      if (e is AgendaServiceException) rethrow;
      throw AgendaServiceException('Erro ao conectar ao servidor: $e');
    }
  }

  /// Exclui uma sessão de estudo no backend.
  Future<void> excluirSessao(String sessaoId) async {
    final uri = Uri.parse('$kBaseUrl/api/sessoes-estudo/$sessaoId/');

    try {
      final response = await http.delete(
        uri,
        headers: kDefaultHeaders,
      );

      if (response.statusCode == 204) {
        return;
      }

      throw AgendaServiceException('Falha ao excluir a sessão de estudo.');
    } catch (e) {
      throw AgendaServiceException('Erro ao conectar ao servidor: $e');
    }
  }
}
