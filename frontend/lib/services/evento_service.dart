import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import 'agenda_service.dart';

class EventoService {
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
      return erros.isNotEmpty ? erros.join('\n') : 'Dados inválidos.';
    } catch (_) {
      return 'Erro inesperado do servidor.';
    }
  }

  /// Cadastra um novo evento acadêmico no backend.
  Future<void> criarEvento({
    required String disciplinaId,
    required String titulo,
    required String tipo,
    required DateTime dataEvento,
    String? horaInicio,
    String? horaFim,
    String? descricao,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/eventos-academicos/');

    final dataString = "${dataEvento.year.toString().padLeft(4, '0')}-"
        "${dataEvento.month.toString().padLeft(2, '0')}-"
        "${dataEvento.day.toString().padLeft(2, '0')}";

    final Map<String, dynamic> body = {
      'disciplina': disciplinaId,
      'titulo': titulo,
      'tipo': tipo,
      'data_evento': dataString,
      'concluido': false,
    };
    if (horaInicio != null) body['hora_inicio'] = horaInicio;
    if (horaFim != null) body['hora_fim'] = horaFim;
    if (descricao != null) body['descricao'] = descricao;

    late http.Response response;
    try {
      response = await http.post(
        uri,
        headers: defaultHeaders,
        body: json.encode(body),
      );
    } catch (e) {
      throw AgendaServiceException('Erro de conexão: $e');
    }

    if (response.statusCode == 201) return;

    throw AgendaServiceException(
      _extrairMensagemErro(response.body),
    );
  }

  /// Atualiza (PATCH) um evento acadêmico no backend.
  Future<void> editarEvento({
    required String eventoId,
    required String disciplinaId,
    required String titulo,
    required String tipo,
    required DateTime dataEvento,
    String? horaInicio,
    String? horaFim,
    String? descricao,
    required bool concluido,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/eventos-academicos/$eventoId/');

    final dataString = "${dataEvento.year.toString().padLeft(4, '0')}-"
        "${dataEvento.month.toString().padLeft(2, '0')}-"
        "${dataEvento.day.toString().padLeft(2, '0')}";

    final Map<String, dynamic> body = {
      'disciplina': disciplinaId,
      'titulo': titulo,
      'tipo': tipo,
      'data_evento': dataString,
      'hora_inicio': horaInicio,
      'hora_fim': horaFim,
      'descricao': descricao,
      'concluido': concluido,
    };

    late http.Response response;
    try {
      response = await http.patch(
        uri,
        headers: defaultHeaders,
        body: json.encode(body),
      );
    } catch (e) {
      throw AgendaServiceException('Erro de conexão: $e');
    }

    if (response.statusCode == 200 || response.statusCode == 204) return;

    throw AgendaServiceException(
      _extrairMensagemErro(response.body),
    );
  }

  /// Exclui um evento acadêmico no backend.
  Future<void> excluirEvento(String eventoId) async {
    final uri = Uri.parse('$kBaseUrl/api/eventos-academicos/$eventoId/');

    late http.Response response;
    try {
      response = await http.delete(uri, headers: defaultHeaders);
    } catch (e) {
      throw AgendaServiceException('Erro de conexão: $e');
    }

    if (response.statusCode == 204) return;

    throw AgendaServiceException('Falha ao excluir o evento acadêmico. Status: ${response.statusCode}');
  }
}
