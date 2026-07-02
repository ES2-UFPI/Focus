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
      return erros.isNotEmpty ? erros.join('\n') : 'Dados inválidos.';
    } catch (_) {
      return 'Erro inesperado do servidor.';
    }
  }

  // 🌟 FUNÇÃO MÁGICA: Garante o envio do horário local com o fuso correto (-03:00)
  static String _formatarParaBackend(DateTime date) {
    final localDate = date.isUtc ? date.toLocal() : date;
    final iso = localDate.toIso8601String();
    final offset = localDate.timeZoneOffset;
    final horas = offset.inHours.abs().toString().padLeft(2, '0');
    final minutos = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sinal = offset.isNegative ? '-' : '+';
    return '$iso$sinal$horas:$minutos'; 
  }

  /// Cadastra uma nova sessão de estudo no backend.
  Future<void> criarSessao({
    required String disciplinaId,
    required DateTime inicio, 
    required DateTime fim,    
    String? descricao,
    required String status,          
    required int duracaoRealizada,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/sessoes-estudo/');

    final body = {
      'disciplina': disciplinaId,
      'inicio': _formatarParaBackend(inicio), // 👈 Formatado com fuso local
      'fim': _formatarParaBackend(fim),       // 👈 Formatado com fuso local
      'status': status, 
      'duracao_realizada': duracaoRealizada, 
      'descricao': descricao,
    };

    try {
      final response = await http.post(
        uri,
        headers: kDefaultHeaders, 
        body: json.encode(body),
      );

      if (response.statusCode == 201) return;
      throw AgendaServiceException(_extrairMensagemErro(response.body));
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
      'inicio': _formatarParaBackend(inicio), // 👈 Formatado com fuso local
      'fim': _formatarParaBackend(fim),       // 👈 Formatado com fuso local
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

      if (response.statusCode == 200 || response.statusCode == 204) return;
      throw AgendaServiceException(_extrairMensagemErro(response.body));
    } catch (e) {
      if (e is AgendaServiceException) rethrow;
      throw AgendaServiceException('Erro ao conectar ao servidor: $e');
    }
  }

  /// Exclui uma sessão de estudo no backend.
  Future<void> excluirSessao(String sessaoId) async {
    final uri = Uri.parse('$kBaseUrl/api/sessoes-estudo/$sessaoId/');
    try {
      final response = await http.delete(uri, headers: kDefaultHeaders);
      if (response.statusCode == 204) return;
      throw AgendaServiceException(_extrairMensagemErro(response.body));
    } catch (e) {
      if (e is AgendaServiceException) rethrow;
      throw AgendaServiceException('Erro ao conectar ao servidor: $e');
    }
  }
}
