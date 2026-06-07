import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import '../models/disciplina_model.dart';
import 'agenda_service.dart'; // Para reutilizar AgendaServiceException se apropriado, ou criamos uma específica

class DisciplinaService {
  /// Obtém o ID de um aluno para vincular a novas disciplinas.
  /// Como não há autenticação, busca o primeiro aluno da lista ou cria um padrão se estiver vazia.
  Future<String> obterOuCriarAlunoId() async {
    final uri = Uri.parse('$kBaseUrl/api/alunos/');
    try {
      final response = await http.get(uri, headers: kDefaultHeaders);
      if (response.statusCode == 200) {
        final List<dynamic> alunos = json.decode(response.body) as List<dynamic>;
        if (alunos.isNotEmpty) {
          return alunos.first['id'] as String;
        }
      }

      // Se a lista estiver vazia ou falhar, criamos um aluno padrão
      final postUri = Uri.parse('$kBaseUrl/api/alunos/');
      final postResponse = await http.post(
        postUri,
        headers: kDefaultHeaders,
        body: json.encode({
          'nome': 'Estudante Focus',
          'email': 'estudante@focus.com',
        }),
      );

      if (postResponse.statusCode == 201) {
        final data = json.decode(postResponse.body) as Map<String, dynamic>;
        return data['id'] as String;
      }

      throw const AgendaServiceException('Erro ao inicializar identificador do aluno.');
    } catch (e) {
      throw AgendaServiceException('Falha de comunicação com o servidor: $e');
    }
  }

  /// Busca a lista de disciplinas cadastradas.
  Future<List<Disciplina>> getDisciplinas() async {
    final uri = Uri.parse('$kBaseUrl/api/disciplinas/');
    try {
      final response = await http.get(uri, headers: kDefaultHeaders);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data.map((jsonItem) => Disciplina.fromJson(jsonItem as Map<String, dynamic>)).toList();
      }
      throw AgendaServiceException('Erro ao buscar disciplinas. Status: ${response.statusCode}');
    } catch (e) {
      throw AgendaServiceException('Erro de conexão: $e');
    }
  }

  /// Cria uma nova disciplina.
  Future<Disciplina> criarDisciplina({
    required String nome,
    String? codigo,
    String? descricao,
    required String cor,
  }) async {
    try {
      final alunoId = await obterOuCriarAlunoId();
      final uri = Uri.parse('$kBaseUrl/api/disciplinas/');
      
      final body = {
        'aluno': alunoId,
        'nome': nome,
        'codigo': codigo,
        'descricao': descricao,
        'cor': cor,
        'meta_horas_semanais': 0.0,
        'ativo': true,
      };

      final response = await http.post(
        uri,
        headers: kDefaultHeaders,
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return Disciplina.fromJson(data);
      }

      // Tratamento de erros do backend
      final Map<String, dynamic> errorData = json.decode(response.body) as Map<String, dynamic>;
      final errorMsgs = errorData.values.expand((v) => v is List ? v : [v]).join(', ');
      throw AgendaServiceException(errorMsgs.isNotEmpty ? errorMsgs : 'Dados inválidos.');
    } catch (e) {
      if (e is AgendaServiceException) rethrow;
      throw AgendaServiceException('Erro de rede ao criar disciplina: $e');
    }
  }
}
