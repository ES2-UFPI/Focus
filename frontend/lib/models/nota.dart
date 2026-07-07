import 'dart:ui';

import 'material_estudo.dart';

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

  /// Converte um MaterialEstudo (tipo 'Resumo') em Nota. Retorna null quando
  /// a descricao não contém nenhum cabeçalho de seção conhecido — ou seja, é
  /// um resumo comum criado fora da tela de Notas.
  static Nota? fromMaterial(MaterialEstudo material) {
    final descricao = material.descricao;
    if (descricao == null || descricao.isEmpty) return null;

    final secoes = _textoParaSecoes(descricao);
    if (secoes == null) return null;

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
      'tipo': 'Resumo',
      'disciplina': disciplinaId,
      'descricao': _secoesParaTexto(secoes),
    };
  }

  /// Gera o texto legível gravado em `descricao`: cabeçalho de cada seção
  /// preenchida seguido dos itens com '- '. Seções vazias são omitidas.
  static String _secoesParaTexto(Map<String, List<String>> secoes) {
    final blocos = <String>[];
    for (final sec in kNotaSecoes) {
      final itens = secoes[sec.key] ?? const [];
      if (itens.isEmpty) continue;
      blocos.add(
        '${sec.label}:\n${itens.map((i) => '- $i').join('\n')}',
      );
    }
    // Nota sem nenhum item ainda: grava só o primeiro cabeçalho para que o
    // material continue reconhecível como nota ao ser recarregado.
    if (blocos.isEmpty) return '${kNotaSecoes.first.label}:';
    return blocos.join('\n\n');
  }

  /// Reconstrói as seções a partir do texto de `descricao`. Retorna null se
  /// nenhum cabeçalho conhecido for encontrado.
  static Map<String, List<String>>? _textoParaSecoes(String texto) {
    final secoes = {
      for (final sec in kNotaSecoes) sec.key: <String>[],
    };
    final labelParaKey = {
      for (final sec in kNotaSecoes) '${sec.label}:': sec.key,
    };

    String? secaoAtual;
    var achouCabecalho = false;
    for (final linhaBruta in texto.split('\n')) {
      final linha = linhaBruta.trim();
      if (linha.isEmpty) continue;
      final key = labelParaKey[linha];
      if (key != null) {
        secaoAtual = key;
        achouCabecalho = true;
        continue;
      }
      if (secaoAtual == null) continue;
      final item = linha.startsWith('- ') ? linha.substring(2).trim() : linha;
      if (item.isNotEmpty) secoes[secaoAtual]!.add(item);
    }

    return achouCabecalho ? secoes : null;
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
