import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/network/api_client.dart';
import '../models/disciplina.dart';
import '../models/material_estudo.dart';
import '../models/dashboard_model.dart';



class ApiService {
  static String get _baseUrl => '$kBaseUrl/api';

  // 🔑 O SEGREDO ESTÁ AQUI: Adicione o modificador static!
  static String? _token;

  void setToken(String token) {
    _token = token;
    if (kDebugMode) {
      debugPrint('🔑 [ApiService] Token guardado na memória global.');
    }
  }

  void clearToken() => _token = null;

  Map<String, String> _headers() {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Token $_token';
      if (kDebugMode) {
        debugPrint('🚀 [ApiService] Enviando requisição autenticada.');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
          '⚠️ [ApiService] AVISO: Enviando requisição sem autenticação.',
        );
      }
    }

    return headers;
  }
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

  Future<DashboardData?> getDashboardConsistencia() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sessoes-estudo/dashboard/'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return DashboardData.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao buscar dashboard: $e');
      }
    }
    return null;
  }
}
