import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/network/api_client.dart';
import '../models/meta_semanal_model.dart';
import 'agenda_service.dart';

class MetasSemanaisService {
  Future<List<MetaSemanal>> listarMetas() async {
    final uri = Uri.parse('$kBaseUrl/api/planejamentos-disciplina/');

    final response = await http.get(
      uri,
      headers: kDefaultHeaders,
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded is List) {
        return decoded.map((e) => MetaSemanal.fromJson(e)).toList();
      }

      if (decoded is Map && decoded['results'] is List) {
        return (decoded['results'] as List)
            .map((e) => MetaSemanal.fromJson(e))
            .toList();
      }
    }

    throw AgendaServiceException('Erro ao carregar metas semanais.');
  }

  Future<void> salvarMeta(MetaSemanal meta) async {
    final isEdicao = meta.id != null;

    final uri = isEdicao
        ? Uri.parse('$kBaseUrl/api/planejamentos-disciplina/${meta.id}/')
        : Uri.parse('$kBaseUrl/api/planejamentos-disciplina/');

    final response = isEdicao
        ? await http.patch(
            uri,
            headers: kDefaultHeaders,
            body: json.encode(meta.toJson()),
          )
        : await http.post(
            uri,
            headers: kDefaultHeaders,
            body: json.encode(meta.toJson()),
          );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    throw AgendaServiceException('Erro ao salvar meta semanal.');
  }
}