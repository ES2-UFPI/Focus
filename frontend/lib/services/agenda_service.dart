/// Serviço responsável por consumir o endpoint unificado da Agenda.
///
/// Isola toda a lógica de rede (requisição HTTP, tratamento de status e
/// deserialização JSON) do restante da aplicação.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/network/api_client.dart';
import '../models/agenda_model.dart';

class AgendaService {
  /// Realiza `GET /api/agenda/` e devolve um [AgendaResponse] parseado.
  ///
  /// Lança [AgendaServiceException] quando a requisição falha ou o servidor
  /// responde com um status diferente de 200.
  Future<AgendaResponse> getAgenda() async {
    final uri = Uri.parse('$kBaseUrl/api/agenda/');

    try {
      final response = await http.get(uri, headers: kDefaultHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return AgendaResponse.fromJson(data);
      }

      throw AgendaServiceException(
        'Erro ao carregar a agenda. Status: ${response.statusCode}',
      );
    } on http.ClientException catch (e) {
      throw AgendaServiceException(
        'Não foi possível conectar ao servidor: ${e.message}',
      );
    } on FormatException {
      throw AgendaServiceException(
        'Resposta inválida do servidor (JSON malformado).',
      );
    }
  }
}

/// Exceção de domínio para erros ocorridos no [AgendaService].
class AgendaServiceException implements Exception {
  final String message;

  const AgendaServiceException(this.message);

  @override
  String toString() => 'AgendaServiceException: $message';
}
