import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/disciplina.dart';
import '../models/material_estudo.dart';

// TODO: substituir pelo token real quando a tela de login for implementada
const _demoToken = 'cdc454f2c8b69920a120b5fa76a953fd7490d32c';

class ApiService {
  static const String _baseUrl = 'http://localhost:8000/api';

  String? _token = _demoToken;

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Token $_token',
  };

  Future<List<Disciplina>> getDisciplinas() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/disciplinas/'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Disciplina.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<MaterialEstudo>> getMateriais({
    String? disciplinaId,
    String? tipo,
    String? search,
  }) async {
    final params = <String, String>{};
    if (disciplinaId != null) params['disciplina'] = disciplinaId;
    if (tipo != null) params['tipo'] = tipo;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('$_baseUrl/materiais-estudo/')
        .replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => MaterialEstudo.fromJson(e)).toList();
    }
    return [];
  }

  Future<MaterialEstudo?> createMaterial(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/materiais-estudo/'),
      headers: _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return MaterialEstudo.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<MaterialEstudo?> updateMaterial(String id, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/materiais-estudo/$id/'),
      headers: _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return MaterialEstudo.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> deleteMaterial(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/materiais-estudo/$id/'),
      headers: _headers(),
    );
    return response.statusCode == 204;
  }
}
