import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/material_estudo.dart';
import 'package:frontend/models/nota.dart';

MaterialEstudo _material(String? descricao) {
  return MaterialEstudo(
    id: 'm1',
    titulo: 'Aula sobre requisitos e backlog',
    tipo: 'Resumo',
    descricao: descricao,
    disciplinaId: 'd1',
    disciplinaNome: 'Engenharia de Software II',
    dataInsercao: DateTime(2026, 7, 5),
  );
}

void main() {
  group('Nota.toMaterialJson', () {
    test('gera Resumo com texto legível por seção, omitindo vazias', () {
      final json = Nota.toMaterialJson(
        titulo: 'Aula sobre requisitos e backlog',
        disciplinaId: 'd1',
        secoes: {
          'obs': ['Backlog precisa estar priorizado.'],
          'livros': ['Sommerville - Engenharia de Software', 'Pressman'],
          'prova': [],
        },
      );

      expect(json['tipo'], 'Resumo');
      expect(json['disciplina'], 'd1');
      expect(
        json['descricao'],
        'Observações importantes:\n'
        '- Backlog precisa estar priorizado.\n'
        '\n'
        'Livros citados:\n'
        '- Sommerville - Engenharia de Software\n'
        '- Pressman',
      );
    });

    test('nota sem itens grava o primeiro cabeçalho para round-trip', () {
      final json = Nota.toMaterialJson(
        titulo: 'Nota vazia',
        disciplinaId: 'd1',
        secoes: {},
      );
      expect(json['descricao'], 'Observações importantes:');
      expect(Nota.fromMaterial(_material(json['descricao'] as String)), isNotNull);
    });
  });

  group('Nota.fromMaterial', () {
    test('round-trip preserva todas as seções', () {
      final secoes = {
        for (final sec in kNotaSecoes) sec.key: ['Item de ${sec.label}'],
      };
      final json = Nota.toMaterialJson(
        titulo: 't',
        disciplinaId: 'd1',
        secoes: secoes,
      );
      final nota = Nota.fromMaterial(_material(json['descricao'] as String));

      expect(nota, isNotNull);
      for (final sec in kNotaSecoes) {
        expect(nota!.itensDe(sec.key), ['Item de ${sec.label}']);
      }
    });

    test('resumo comum sem cabeçalhos conhecidos não vira nota', () {
      expect(
        Nota.fromMaterial(_material('Um resumo livre escrito na biblioteca.')),
        isNull,
      );
      expect(Nota.fromMaterial(_material(null)), isNull);
      expect(Nota.fromMaterial(_material('')), isNull);
    });

    test('preenche metadados a partir do material', () {
      final nota = Nota.fromMaterial(
        _material('Dicas para prova:\n- Saber explicar user story.'),
      )!;
      expect(nota.id, 'm1');
      expect(nota.titulo, 'Aula sobre requisitos e backlog');
      expect(nota.disciplinaId, 'd1');
      expect(nota.disciplinaNome, 'Engenharia de Software II');
      expect(nota.itensDe('prova'), ['Saber explicar user story.']);
      expect(nota.snippet, 'Saber explicar user story.');
      expect(nota.dataCurta, '05/07/2026');
    });
  });
}
