import '../models/disciplina.dart';
import '../models/nota_estudo.dart';
import 'api_service.dart';

/// Servico de notas de estudo. Reusa o endpoint /api/materiais-estudo/:
/// cada nota e um MaterialEstudo marcado com o prefixo [NOTA] no titulo.
class NotasService {
  final ApiService _api;

  NotasService({ApiService? api}) : _api = api ?? ApiService();

  Future<List<Disciplina>> listarDisciplinas() => _api.getDisciplinas();

  Future<List<NotaEstudo>> listarNotas() async {
    final materiais = await _api.getMateriais();
    return materiais
        .map(NotaEstudo.fromMaterial)
        .whereType<NotaEstudo>()
        .toList()
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  Future<NotaEstudo?> salvarNota(NotaEstudo nota) async {
    final material = nota.id == null
        ? await _api.createMaterial(nota.toMaterialPayload())
        : await _api.updateMaterial(nota.id!, nota.toMaterialPayload());
    if (material == null) return null;
    return NotaEstudo.fromMaterial(material);
  }

  Future<bool> excluirNota(String id) => _api.deleteMaterial(id);
}
