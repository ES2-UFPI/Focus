import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import '../models/disciplina_model.dart';
import 'agenda_service.dart';

class DisciplinaService {
  Future<List<Disciplina>> getDisciplinas() async {
    final uri = Uri.parse('$kBaseUrl/api/disciplinas/');
    try {
      final response = await http.get(uri, headers: defaultHeaders);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data.map((j) => Disciplina.fromJson(j as Map<String, dynamic>)).toList();
      }
      throw AgendaServiceException('Erro ao buscar disciplinas. Status: ${response.statusCode}');
    } catch (e) {
      if (e is AgendaServiceException) rethrow;
      throw AgendaServiceException('Erro de conexão: $e');
    }
  }

  Future<Disciplina> criarDisciplina({
    required String nome,
    String? codigo,
    String? descricao,
    required String cor,
  }) async {
    final uri = Uri.parse('$kBaseUrl/api/disciplinas/');
    final body = {
      'nome': nome,
      if (codigo != null && codigo.isNotEmpty) 'codigo': codigo,
      if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
      'cor': cor,
      'meta_horas_semanais': 0.0,
      'ativo': true,
    };

    try {
      final response = await http.post(
        uri,
        headers: defaultHeaders,
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return Disciplina.fromJson(json.decode(response.body) as Map<String, dynamic>);
      }

      final errorData = json.decode(response.body) as Map<String, dynamic>;
      final errorMsgs = errorData.values.expand((v) => v is List ? v : [v]).join(', ');
      throw AgendaServiceException(errorMsgs.isNotEmpty ? errorMsgs : 'Dados inválidos.');
    } catch (e) {
      if (e is AgendaServiceException) rethrow;
      throw AgendaServiceException('Erro de rede ao criar disciplina: $e');
    }
  }
}
