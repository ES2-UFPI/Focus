import 'dart:convert';

import 'package:flutter/material.dart';

import 'material_estudo.dart';

/// Prefixo usado no titulo do MaterialEstudo para marcar registros que sao
/// notas de estudo (o backend nao tem endpoint proprio de notas).
const String kNotaTituloPrefixo = '[NOTA] ';

/// Tipo de nota, com cores do design.
enum TipoNota {
  aula('AULA', 'Aula', Color(0xFF6366F1), Color(0xFFEEF0FE)),
  prova('PROVA', 'Prova', Color(0xFFE53935), Color(0xFFFDEAEA)),
  trabalho('TRABALHO', 'Trabalho', Color(0xFFFFA726), Color(0xFFFFF4E5)),
  leitura('LEITURA', 'Leitura', Color(0xFF009688), Color(0xFFE1F1EF)),
  carreira('CARREIRA', 'Carreira', Color(0xFF7E57C2), Color(0xFFF1ECF9));

  final String codigo;
  final String label;
  final Color cor;
  final Color corSoft;

  const TipoNota(this.codigo, this.label, this.cor, this.corSoft);

  static TipoNota fromCodigo(String? codigo) {
    return TipoNota.values.firstWhere(
      (t) => t.codigo == codigo,
      orElse: () => TipoNota.aula,
    );
  }
}

/// Definicao de uma secao estruturada da nota.
class SecaoNotaDef {
  final String key;
  final String label;
  final String placeholder;

  const SecaoNotaDef(this.key, this.label, this.placeholder);
}

const List<SecaoNotaDef> kSecoesNota = [
  SecaoNotaDef('obs', 'Observações importantes',
      'Escreva pontos importantes da aula...'),
  SecaoNotaDef('prova', 'Dicas para prova',
      'O que o professor destacou? O que pode cair?'),
  SecaoNotaDef('artigos', 'Artigos citados',
      'Nome do artigo, autor, link, comentário...'),
  SecaoNotaDef('livros', 'Livros citados',
      'Livro, capítulo, páginas, autor...'),
  SecaoNotaDef('carreira', 'Dicas profissionais e cursos',
      'Cursos indicados, ferramentas, mercado, carreira...'),
  SecaoNotaDef('duvidas', 'Dúvidas pendentes',
      'O que você ainda precisa revisar?'),
  SecaoNotaDef('conceitos', 'Conceitos-chave',
      'Termos e definições centrais desta nota...'),
  SecaoNotaDef('revisao', 'Questões para revisar',
      'Perguntas para testar seu entendimento depois...'),
];

/// Nota de estudo persistida como MaterialEstudo (tipo 'Resumo') com as
/// secoes serializadas em JSON no campo descricao.
class NotaEstudo {
  final String? id;
  final String disciplinaId;
  final String disciplinaNome;
  final String titulo;
  final TipoNota tipo;
  final DateTime data;
  final Map<String, List<String>> secoes;

  const NotaEstudo({
    this.id,
    required this.disciplinaId,
    required this.disciplinaNome,
    required this.titulo,
    required this.tipo,
    required this.data,
    required this.secoes,
  });

  List<String> secao(String key) => secoes[key] ?? const [];

  String get snippet {
    for (final def in kSecoesNota) {
      final itens = secao(def.key);
      if (itens.isNotEmpty) return itens.first;
    }
    return 'Sem observações ainda.';
  }

  String get dataCurta {
    final d = data.day.toString().padLeft(2, '0');
    final m = data.month.toString().padLeft(2, '0');
    return '$d/$m/${data.year}';
  }

  /// Verifica se um MaterialEstudo representa uma nota de estudo.
  static bool ehNota(MaterialEstudo material) {
    if (!material.titulo.startsWith(kNotaTituloPrefixo.trim())) return false;
    final descricao = material.descricao;
    if (descricao == null || descricao.isEmpty) return false;
    try {
      final json = jsonDecode(descricao);
      return json is Map<String, dynamic> && json['nota'] == true;
    } catch (_) {
      return false;
    }
  }

  static NotaEstudo? fromMaterial(MaterialEstudo material) {
    if (!ehNota(material)) return null;
    final json = jsonDecode(material.descricao!) as Map<String, dynamic>;
    final secoesJson = json['secoes'];
    final secoes = <String, List<String>>{};
    if (secoesJson is Map<String, dynamic>) {
      for (final def in kSecoesNota) {
        final itens = secoesJson[def.key];
        secoes[def.key] = itens is List
            ? itens.map((e) => e.toString()).toList()
            : <String>[];
      }
    }
    var titulo = material.titulo;
    if (titulo.startsWith(kNotaTituloPrefixo)) {
      titulo = titulo.substring(kNotaTituloPrefixo.length);
    } else {
      titulo = titulo.substring(kNotaTituloPrefixo.trim().length).trim();
    }
    return NotaEstudo(
      id: material.id,
      disciplinaId: material.disciplinaId,
      disciplinaNome: material.disciplinaNome,
      titulo: titulo,
      tipo: TipoNota.fromCodigo(json['tipo'] as String?),
      data: material.dataInsercao,
      secoes: secoes,
    );
  }

  /// Payload para criar/atualizar via /api/materiais-estudo/.
  Map<String, dynamic> toMaterialPayload() {
    return {
      'titulo': '$kNotaTituloPrefixo$titulo',
      'tipo': 'Resumo',
      'disciplina': disciplinaId,
      'descricao': jsonEncode({
        'nota': true,
        'tipo': tipo.codigo,
        'secoes': {
          for (final def in kSecoesNota) def.key: secao(def.key),
        },
      }),
    };
  }

  NotaEstudo copyWith({
    String? disciplinaId,
    String? disciplinaNome,
    String? titulo,
    TipoNota? tipo,
    Map<String, List<String>>? secoes,
  }) {
    return NotaEstudo(
      id: id,
      disciplinaId: disciplinaId ?? this.disciplinaId,
      disciplinaNome: disciplinaNome ?? this.disciplinaNome,
      titulo: titulo ?? this.titulo,
      tipo: tipo ?? this.tipo,
      data: data,
      secoes: secoes ?? this.secoes,
    );
  }
}
