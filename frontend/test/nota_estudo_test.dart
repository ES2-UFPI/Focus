import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/disciplina.dart';
import 'package:frontend/models/material_estudo.dart';
import 'package:frontend/models/nota_estudo.dart';

void main() {
  group('NotaEstudo', () {
    final nota = NotaEstudo(
      disciplinaId: 'd1',
      disciplinaNome: 'Engenharia de Software II',
      titulo: 'Aula sobre requisitos',
      data: DateTime(2026, 7, 8),
      secoes: const {
        'obs': ['Requisitos ligados a user stories'],
        'prova': ['Funcional vs nao funcional'],
      },
    );

    test('toMaterialPayload marca a nota e serializa as secoes', () {
      final payload = nota.toMaterialPayload();
      expect(payload['titulo'], '[NOTA] Aula sobre requisitos');
      expect(payload['tipo'], 'Resumo');
      expect(payload['disciplina'], 'd1');
      expect(payload['descricao'], contains('"nota":true'));
    });

    test('round-trip via MaterialEstudo preserva os dados', () {
      final payload = nota.toMaterialPayload();
      final material = MaterialEstudo.fromJson({
        ...payload,
        'id': 'm1',
        'disciplina_nome': 'Engenharia de Software II',
        'data_insercao': '2026-07-08T10:00:00',
      });
      expect(NotaEstudo.ehNota(material), isTrue);
      final volta = NotaEstudo.fromMaterial(material)!;
      expect(volta.titulo, 'Aula sobre requisitos');
      expect(volta.secao('obs'), ['Requisitos ligados a user stories']);
      expect(volta.secao('prova'), ['Funcional vs nao funcional']);
      expect(volta.secao('livros'), isEmpty);
    });

    test('nota antiga com campo tipo no JSON continua sendo lida', () {
      final material = MaterialEstudo.fromJson({
        'id': 'm3',
        'titulo': '[NOTA] Nota antiga',
        'tipo': 'Resumo',
        'disciplina': 'd1',
        'descricao':
            '{"nota":true,"tipo":"PROVA","secoes":{"obs":["item antigo"]}}',
        'data_insercao': '2026-07-01T10:00:00',
      });
      final volta = NotaEstudo.fromMaterial(material);
      expect(volta, isNotNull);
      expect(volta!.titulo, 'Nota antiga');
      expect(volta.secao('obs'), ['item antigo']);
    });

    test('material comum nao e tratado como nota', () {
      final material = MaterialEstudo.fromJson({
        'id': 'm2',
        'titulo': 'Slides da aula',
        'tipo': 'PDF',
        'disciplina': 'd1',
        'descricao': 'apenas texto',
        'data_insercao': '2026-07-08T10:00:00',
      });
      expect(NotaEstudo.ehNota(material), isFalse);
      expect(NotaEstudo.fromMaterial(material), isNull);
    });
  });

  group('Disciplina', () {
    test('fromJson tolera codigo null (disciplina cadastrada sem codigo)', () {
      final disciplina = Disciplina.fromJson({
        'id': 'd9',
        'nome': 'Biologia',
        'codigo': null,
        'cor': '#4CAF50',
      });
      expect(disciplina.nome, 'Biologia');
      expect(disciplina.codigo, '');
    });
  });
}
