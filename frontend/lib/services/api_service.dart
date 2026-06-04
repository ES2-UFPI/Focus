import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/disciplina.dart';
import '../models/material_estudo.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000/api';
  static const _storage = FlutterSecureStorage();

  Future<String?> getToken() => _storage.read(key: 'auth_token');

  Future<void> saveToken(String token) =>
      _storage.write(key: 'auth_token', value: token);

  Future<void> clearToken() => _storage.delete(key: 'auth_token');

  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/auth/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)['token'] as String;
      await saveToken(token);
      return token;
    }
    return null;
  }

  Future<List<Disciplina>> getDisciplinas() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/disciplinas/'),
      headers: await _headers(),
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

    final uri = Uri.parse('$_baseUrl/materiais-estudo/').replace(queryParameters: params.isEmpty ? null : params);
    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => MaterialEstudo.fromJson(e)).toList();
    }
    return [];
  }

  Future<MaterialEstudo?> createMaterial(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/materiais-estudo/'),
      headers: await _headers(),
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
      headers: await _headers(),
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
      headers: await _headers(),
    );
    return response.statusCode == 204;
  }
}
