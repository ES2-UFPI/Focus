import 'dart:convert';
import 'dart:ui';

import 'material_estudo.dart';

/// Marcador que identifica um MaterialEstudo cuja descricao guarda uma nota.
const String kNotaMarker = '_focusNota';

/// Converte a cor hex da disciplina (ex.: '#6366F1') em Color.
Color corFromHex(String hex) {
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  return Color(int.tryParse(value, radix: 16) ?? 0xFF6366F1);
}

class NotaSecaoDef {
  final String key;
  final String label;
  final String placeholder;

  const NotaSecaoDef({
    required this.key,
    required this.label,
    required this.placeholder,
  });
}

const List<NotaSecaoDef> kNotaSecoes = [
  NotaSecaoDef(
    key: 'obs',
    label: 'Observações importantes',
    placeholder: 'Escreva pontos importantes da aula...',
  ),
  NotaSecaoDef(
    key: 'prova',
    label: 'Dicas para prova',
    placeholder: 'O que o professor destacou? O que pode cair?',
  ),
  NotaSecaoDef(
    key: 'artigos',
    label: 'Artigos citados',
    placeholder: 'Nome do artigo, autor, link, comentário...',
  ),
  NotaSecaoDef(
    key: 'livros',
    label: 'Livros citados',
    placeholder: 'Livro, capítulo, páginas, autor...',
  ),
  NotaSecaoDef(
    key: 'carreira',
    label: 'Dicas profissionais e cursos',
    placeholder: 'Cursos indicados, ferramentas, mercado, carreira...',
  ),
  NotaSecaoDef(
    key: 'duvidas',
    label: 'Dúvidas pendentes',
    placeholder: 'O que você ainda precisa revisar?',
  ),
  NotaSecaoDef(
    key: 'conceitos',
    label: 'Conceitos-chave',
    placeholder: 'Termos e definições centrais desta nota...',
  ),
  NotaSecaoDef(
    key: 'revisao',
    label: 'Questões para revisar',
    placeholder: 'Perguntas para testar seu entendimento depois...',
  ),
];

/// Uma nota de estudo, persistida como MaterialEstudo (tipo 'Outro') com as
/// seções serializadas em JSON no campo `descricao`.
class Nota {
  final String id;
  final String titulo;
  final String disciplinaId;
  final String disciplinaNome;
  final Map<String, List<String>> secoes;
  final DateTime dataInsercao;

  const Nota({
    required this.id,
    required this.titulo,
    required this.disciplinaId,
    required this.disciplinaNome,
    required this.secoes,
    required this.dataInsercao,
  });

  /// Converte um MaterialEstudo em Nota. Retorna null quando a descricao não
  /// é o JSON marcado — ou seja, é um material comum.
  static Nota? fromMaterial(MaterialEstudo material) {
    final descricao = material.descricao;
    if (descricao == null || descricao.isEmpty) return null;

    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(descricao);
      if (decoded is! Map<String, dynamic> ||
          !decoded.containsKey(kNotaMarker)) {
        return null;
      }
      payload = decoded;
    } catch (_) {
      return null;
    }

    final secoes = <String, List<String>>{};
    for (final sec in kNotaSecoes) {
      final raw = payload[sec.key];
      secoes[sec.key] = raw is List
          ? raw.map((e) => e.toString()).toList()
          : <String>[];
    }

    return Nota(
      id: material.id,
      titulo: material.titulo,
      disciplinaId: material.disciplinaId,
      disciplinaNome: material.disciplinaNome,
      secoes: secoes,
      dataInsercao: material.dataInsercao,
    );
  }

  /// Payload para criar/atualizar o MaterialEstudo correspondente.
  static Map<String, dynamic> toMaterialJson({
    required String titulo,
    required String disciplinaId,
    required Map<String, List<String>> secoes,
  }) {
    return {
      'titulo': titulo,
      'tipo': 'Outro',
      'disciplina': disciplinaId,
      'descricao': jsonEncode({
        kNotaMarker: 1,
        for (final sec in kNotaSecoes) sec.key: secoes[sec.key] ?? <String>[],
      }),
    };
  }

  List<String> itensDe(String key) => secoes[key] ?? const [];

  /// Primeira linha da primeira seção preenchida, usada como resumo no card.
  String get snippet {
    for (final sec in kNotaSecoes) {
      final itens = itensDe(sec.key);
      if (itens.isNotEmpty) return itens.first;
    }
    return 'Sem observações ainda.';
  }

  String get dataCurta {
    final d = dataInsercao;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
