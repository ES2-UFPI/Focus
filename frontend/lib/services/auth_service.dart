import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _baseUrl = 'http://localhost:8000/api';
const _tokenKey = 'auth_token';
const _alunoKey = 'auth_aluno';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String senha) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _salvar(data['token'], data['aluno']);
      return {'sucesso': true, 'aluno': data['aluno']};
    }
    final erros = jsonDecode(response.body);
    return {'sucesso': false, 'erro': _extrairErro(erros)};
  }

  static Future<Map<String, dynamic>> registro({
    required String nome,
    required String email,
    required String senha,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/registro/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nome': nome, 'email': email, 'senha': senha}),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _salvar(data['token'], data['aluno']);
      return {'sucesso': true, 'aluno': data['aluno']};
    }
    final erros = jsonDecode(response.body);
    return {'sucesso': false, 'erro': _extrairErro(erros)};
  }

  static Future<void> _salvar(String token, Map aluno) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_alunoKey, jsonEncode(aluno));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getAluno() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_alunoKey);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  static Future<bool> estaLogado() async {
    final token = await getToken();
    return token != null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_alunoKey);
  }

  static String _extrairErro(dynamic erros) {
    if (erros is Map) {
      for (final val in erros.values) {
        if (val is List && val.isNotEmpty) return val.first.toString();
        if (val is String) return val;
      }
    }
    return 'Erro desconhecido.';
  }
}
