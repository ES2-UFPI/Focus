from datetime import timedelta

from django.test import TestCase
from django.utils import timezone

from alunos.models import Aluno
from disciplinas.models import Disciplina
from sessao_estudo.models import SessaoEstudo
from sessao_estudo.serializers import SessaoEstudoSerializer


class SessaoEstudoDadosInsightsTests(TestCase):
    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='insights@teste.com',
            nome='Aluno Insights',
            password='senha123',
        )
        self.disciplina = Disciplina.objects.create(
            aluno=self.aluno,
            nome='Estatística',
            cor='#6366F1',
            meta_horas_semanais=4,
        )
        self.inicio = timezone.now() + timedelta(days=1)
        self.fim = self.inicio + timedelta(hours=1)

    def test_serializer_persiste_campos_opcionais_de_coleta(self):
        serializer = SessaoEstudoSerializer(
            data={
                'disciplina': str(self.disciplina.id),
                'inicio': self.inicio.isoformat(),
                'fim': self.fim.isoformat(),
                'status': SessaoEstudo.StatusSessao.AGENDADO,
                'duracao_realizada': 25,
                'descricao': 'Lista 3',
                'energia_inicial': 4,
                'interrupcoes': 2,
                'tipo_atividade': SessaoEstudo.TipoAtividade.EXERCICIO,
            }
        )

        self.assertTrue(serializer.is_valid(), serializer.errors)
        sessao = serializer.save()

        self.assertEqual(sessao.energia_inicial, 4)
        self.assertEqual(sessao.interrupcoes, 2)
        self.assertEqual(
            sessao.tipo_atividade,
            SessaoEstudo.TipoAtividade.EXERCICIO,
        )
        self.assertEqual(sessao.descricao, 'Lista 3')

    def test_energia_fora_da_escala_e_rejeitada(self):
        serializer = SessaoEstudoSerializer(
            data={
                'disciplina': str(self.disciplina.id),
                'inicio': self.inicio.isoformat(),
                'fim': self.fim.isoformat(),
                'status': SessaoEstudo.StatusSessao.AGENDADO,
                'duracao_realizada': 0,
                'energia_inicial': 6,
                'interrupcoes': 0,
            }
        )   

        self.assertFalse(serializer.is_valid())
        self.assertIn('energia_inicial', serializer.errors)

    def test_tipo_de_atividade_invalido_e_rejeitado(self):
        serializer = SessaoEstudoSerializer(
            data={
                'disciplina': str(self.disciplina.id),
                'inicio': self.inicio.isoformat(),
                'fim': self.fim.isoformat(),
                'status': SessaoEstudo.StatusSessao.AGENDADO,
                'duracao_realizada': 0,
                'interrupcoes': 0,
                'tipo_atividade': 'VIDEO',
            }
        )

        self.assertFalse(serializer.is_valid())
        self.assertIn('tipo_atividade', serializer.errors)
