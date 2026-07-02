from django.db import IntegrityError
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from alunos.models import Aluno
from disciplinas.models import Disciplina
from feedback_sessao_estudo.models import FeedbackSessaoEstudo
from sessao_estudo.models import SessaoEstudo


class FeedbackSessaoEstudoModelTests(APITestCase):

    def setUp(self):
        self.aluno = Aluno.objects.create_user(email='aluno@teste.com', nome='Aluno', password='senha123')
        self.disciplina = Disciplina.objects.create(aluno=self.aluno, nome='Cálculo I')
        inicio = timezone.now()
        self.sessao = SessaoEstudo.objects.create(
            disciplina=self.disciplina,
            inicio=inicio,
            fim=inicio + timezone.timedelta(hours=1),
            duracao_realizada=60,
            status=SessaoEstudo.StatusSessao.CONCLUIDO,
        )

    def test_str_retorna_produtividade_formatada(self):
        feedback = FeedbackSessaoEstudo.objects.create(
            sessao_estudo=self.sessao,
            produtividade=FeedbackSessaoEstudo.NivelProdutividade.ALTA,
        )
        self.assertIn('Alta', str(feedback))

    def test_uma_sessao_so_pode_ter_um_feedback(self):
        FeedbackSessaoEstudo.objects.create(
            sessao_estudo=self.sessao,
            produtividade=FeedbackSessaoEstudo.NivelProdutividade.REGULAR,
        )
        with self.assertRaises(IntegrityError):
            FeedbackSessaoEstudo.objects.create(
                sessao_estudo=self.sessao,
                produtividade=FeedbackSessaoEstudo.NivelProdutividade.BAIXA,
            )


class FeedbackSessaoEstudoAPITests(APITestCase):

    def setUp(self):
        self.aluno = Aluno.objects.create_user(email='aluno@teste.com', nome='Aluno', password='senha123')
        self.disciplina = Disciplina.objects.create(aluno=self.aluno, nome='Cálculo I')
        inicio = timezone.now()
        self.sessao = SessaoEstudo.objects.create(
            disciplina=self.disciplina,
            inicio=inicio,
            fim=inicio + timezone.timedelta(hours=1),
            duracao_realizada=60,
            status=SessaoEstudo.StatusSessao.CONCLUIDO,
        )
        self.feedback = FeedbackSessaoEstudo.objects.create(
            sessao_estudo=self.sessao,
            produtividade=FeedbackSessaoEstudo.NivelProdutividade.ALTA,
        )

    def test_endpoint_exige_autenticacao(self):
        response = self.client.get('/api/feedbacks-sessao/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_listar_feedbacks_autenticado(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.get('/api/feedbacks-sessao/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        ids = [item['id'] for item in response.data]
        self.assertIn(str(self.feedback.id), ids)

    def test_criar_feedback_para_sessao(self):
        outra_sessao = SessaoEstudo.objects.create(
            disciplina=self.disciplina,
            inicio=timezone.now() + timezone.timedelta(days=1),
            fim=timezone.now() + timezone.timedelta(days=1, hours=1),
            duracao_realizada=30,
            status=SessaoEstudo.StatusSessao.CONCLUIDO,
        )
        self.client.force_authenticate(user=self.aluno)
        response = self.client.post('/api/feedbacks-sessao/', {
            'sessao_estudo': str(outra_sessao.id),
            'produtividade': FeedbackSessaoEstudo.NivelProdutividade.MUITO_ALTA,
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(FeedbackSessaoEstudo.objects.filter(sessao_estudo=outra_sessao).exists())

    def test_criar_feedback_duplicado_para_mesma_sessao_falha(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.post('/api/feedbacks-sessao/', {
            'sessao_estudo': str(self.sessao.id),
            'produtividade': FeedbackSessaoEstudo.NivelProdutividade.BAIXA,
        })
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_criar_feedback_com_produtividade_invalida_falha(self):
        outra_sessao = SessaoEstudo.objects.create(
            disciplina=self.disciplina,
            inicio=timezone.now() + timezone.timedelta(days=2),
            fim=timezone.now() + timezone.timedelta(days=2, hours=1),
            duracao_realizada=30,
            status=SessaoEstudo.StatusSessao.CONCLUIDO,
        )
        self.client.force_authenticate(user=self.aluno)
        response = self.client.post('/api/feedbacks-sessao/', {
            'sessao_estudo': str(outra_sessao.id),
            'produtividade': 99,
        })
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
