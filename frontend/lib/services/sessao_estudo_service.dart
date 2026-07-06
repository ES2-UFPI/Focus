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
  final DateTime inicio;
  final DateTime fim;
  final int duracaoRealizada;
  final String status;
  final int? energiaInicial;
  final int interrupcoes;
  final String? tipoAtividade;

  SessaoEstudoResumo({
    required this.id,
    required this.disciplinaId,
    required this.disciplinaNome,
    required this.inicio,
    required this.fim,
    required this.duracaoRealizada,
    required this.status,
    this.energiaInicial,
    this.interrupcoes = 0,
    this.tipoAtividade,
  });

  factory SessaoEstudoResumo.fromJson(Map<String, dynamic> json) {
    return SessaoEstudoResumo(
      id: json['id'] as String,
      disciplinaId: json['disciplina'] as String,
      disciplinaNome: json['disciplina_nome'] as String? ?? '',
      inicio: DateTime.parse(json['inicio'] as String).toLocal(),
      fim: DateTime.parse(json['fim'] as String).toLocal(),
      duracaoRealizada: json['duracao_realizada'] as int? ?? 0,
      status: json['status'] as String? ?? 'AGENDADO',
      energiaInicial: json['energia_inicial'] as int?,
      interrupcoes: json['interrupcoes'] as int? ?? 0,
      tipoAtividade: json['tipo_atividade'] as String?,
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
    required int? energiaInicial,
    required int interrupcoes,
    required String? tipoAtividade,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/sessoes-estudo/');

    final body = {
      'disciplina': disciplinaId,
      'inicio': _formatarParaBackend(inicio), // 👈 Formatado com fuso local
      'fim': _formatarParaBackend(fim), // 👈 Formatado com fuso local
      'status': status,
      'duracao_realizada': duracaoRealizada,
      'descricao': descricao,
      'energia_inicial': energiaInicial,
      'interrupcoes': interrupcoes,
      'tipo_atividade': tipoAtividade,
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
    required int? energiaInicial,
    required int interrupcoes,
    required String? tipoAtividade,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/sessoes-estudo/$sessaoId/');

    final body = {
      'disciplina': disciplinaId,
      'inicio': _formatarParaBackend(inicio), // 👈 Formatado com fuso local
      'fim': _formatarParaBackend(fim), // 👈 Formatado com fuso local
      'status': status,
      'duracao_realizada': duracaoRealizada,
      'descricao': descricao,
      'energia_inicial': energiaInicial,
      'interrupcoes': interrupcoes,
      'tipo_atividade': tipoAtividade,
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

  /// Lista todas as sessões de estudo do aluno logado (usado pelo Pomodoro
  /// para o seletor de matéria → sessão agendada).
  Future<List<SessaoEstudoResumo>> listarSessoes() async {
    final uri = Uri.parse('$kBaseUrl/api/sessoes-estudo/');

    try {
      final response = await http.get(uri, headers: kDefaultHeaders);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final lista = decoded is List
            ? decoded
            : (decoded as Map<String, dynamic>)['results'] as List<dynamic>;
        return lista
            .map((e) => SessaoEstudoResumo.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw AgendaServiceException(_extrairMensagemErro(response.body));
    } catch (e) {
      if (e is AgendaServiceException) rethrow;
      throw AgendaServiceException('Erro ao conectar ao servidor: $e');
    }
  }

  /// Busca as sessões de estudo da semana atual (usado pelo Pomodoro para
  /// horas por dia, sessões concluídas hoje e histórico).
  Future<List<SessaoEstudoResumo>> getSemanaAtual() async {
    final uri = Uri.parse('$kBaseUrl/api/sessoes-estudo/semana_atual/');

    try {
      final response = await http.get(uri, headers: kDefaultHeaders);

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

  /// Registra um bloco individual do Pomodoro. Blocos concluídos nascem sem
  /// produtividade para que a UI possa persistir o ciclo imediatamente e
  /// coletar a nota opcional logo depois.
  Future<String> criarBlocoPomodoro({
    required String sessaoId,
    required int numeroCiclo,
    required DateTime inicio,
    required DateTime fim,
    required int duracaoPlanejadaSegundos,
    required int duracaoRealizadaSegundos,
    required int interrupcoes,
    required String status,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/blocos-pomodoro/');
    final body = {
      'sessao_estudo': sessaoId,
      'numero_ciclo': numeroCiclo,
      'inicio': _formatarParaBackend(inicio),
      'fim': _formatarParaBackend(fim),
      'duracao_planejada_segundos': duracaoPlanejadaSegundos,
      'duracao_realizada_segundos': duracaoRealizadaSegundos,
      'interrupcoes': interrupcoes,
      'status': status,
      'produtividade': null,
    };

    try {
      final response = await http.post(
        uri,
        headers: kDefaultHeaders,
        body: json.encode(body),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['id'] as String;
      }
      throw AgendaServiceException(_extrairMensagemErro(response.body));
    } catch (e) {
      if (e is AgendaServiceException) rethrow;
      throw AgendaServiceException('Erro ao conectar ao servidor: $e');
    }
  }

  Future<void> avaliarBlocoPomodoro({
    required String blocoId,
    required int produtividade,
    String? status,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/blocos-pomodoro/$blocoId/');
    final body = <String, dynamic>{'produtividade': produtividade};
    if (status != null) body['status'] = status;
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
