import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import 'agenda_service.dart';

class EventoService {
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

    // Formatando data como YYYY-MM-DD
    final dataString = "${dataEvento.year.toString().padLeft(4, '0')}-"
        "${dataEvento.month.toString().padLeft(2, '0')}-"
        "${dataEvento.day.toString().padLeft(2, '0')}";

    final body = {
      'disciplina': disciplinaId,
      'titulo': titulo,
      'tipo': tipo,
      'data_evento': dataString,
      'hora_inicio': horaInicio,
      'hora_fim': horaFim,
      'descricao': descricao,
      'concluido': false,
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

      // Tenta extrair a mensagem de erro detalhada retornada pelo Django
      final Map<String, dynamic> errorData = json.decode(response.body) as Map<String, dynamic>;
      
      // Se houver erros não relacionados a campos específicos (non_field_errors) ou erros de campo
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

    final body = {
      'disciplina': disciplinaId,
      'titulo': titulo,
      'tipo': tipo,
      'data_evento': dataString,
      'hora_inicio': horaInicio,
      'hora_fim': horaFim,
      'descricao': descricao,
      'concluido': concluido,
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

  /// Exclui um evento acadêmico no backend.
  Future<void> excluirEvento(String eventoId) async {
    final uri = Uri.parse('$kBaseUrl/api/eventos-academicos/$eventoId/');

    try {
      final response = await http.delete(
        uri,
        headers: defaultHeaders,
      );

      if (response.statusCode == 204) {
        return;
      }

      throw AgendaServiceException('Falha ao excluir o evento acadêmico.');
    } catch (e) {
      throw AgendaServiceException('Erro ao conectar ao servidor: $e');
    }
  }
}
