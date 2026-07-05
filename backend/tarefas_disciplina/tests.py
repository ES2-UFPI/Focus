from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from alunos.models import Aluno
from disciplinas.models import Disciplina
from tarefas_disciplina.models import Prioridade, TarefaDisciplina


class TarefaDisciplinaModelTests(APITestCase):

    def setUp(self):
        self.aluno = Aluno.objects.create_user(email='aluno@teste.com', nome='Aluno', password='senha123')
        self.disciplina = Disciplina.objects.create(aluno=self.aluno, nome='Cálculo I')

    def test_str_retorna_titulo(self):
        tarefa = TarefaDisciplina.objects.create(
            disciplina=self.disciplina,
            titulo='Resolver lista 1',
            prazo=timezone.now() + timezone.timedelta(days=3),
        )
        self.assertEqual(str(tarefa), 'Resolver lista 1')

    def test_prioridade_padrao_e_media(self):
        tarefa = TarefaDisciplina.objects.create(
            disciplina=self.disciplina,
            titulo='Resolver lista 1',
            prazo=timezone.now() + timezone.timedelta(days=3),
        )
        self.assertEqual(tarefa.prioridade, Prioridade.MEDIA)

    def test_concluida_padrao_falso(self):
        tarefa = TarefaDisciplina.objects.create(
            disciplina=self.disciplina,
            titulo='Resolver lista 1',
            prazo=timezone.now() + timezone.timedelta(days=3),
        )
        self.assertFalse(tarefa.concluida)

    def test_ordenacao_por_prazo(self):
        tarefa_distante = TarefaDisciplina.objects.create(
            disciplina=self.disciplina,
            titulo='Tarefa Distante',
            prazo=timezone.now() + timezone.timedelta(days=10),
        )
        tarefa_proxima = TarefaDisciplina.objects.create(
            disciplina=self.disciplina,
            titulo='Tarefa Próxima',
            prazo=timezone.now() + timezone.timedelta(days=1),
        )
        tarefas = list(TarefaDisciplina.objects.all())
        self.assertEqual(tarefas[0], tarefa_proxima)
        self.assertEqual(tarefas[1], tarefa_distante)

    def test_evento_deletado_mantem_tarefa_sem_evento(self):
        from eventos_academicos.models import EventoAcademico

        evento = EventoAcademico.objects.create(
            disciplina=self.disciplina,
            titulo='Prova 1',
            tipo=EventoAcademico.TipoEvento.PROVA,
            data_evento=timezone.localdate() + timezone.timedelta(days=5),
        )
        tarefa = TarefaDisciplina.objects.create(
            disciplina=self.disciplina,
            titulo='Estudar para a prova',
            prazo=timezone.now() + timezone.timedelta(days=4),
            evento=evento,
        )
        evento.delete()
        tarefa.refresh_from_db()
        self.assertIsNone(tarefa.evento)


class TarefaDisciplinaAPITests(APITestCase):

    def setUp(self):
        self.aluno = Aluno.objects.create_user(email='aluno@teste.com', nome='Aluno', password='senha123')
        self.disciplina = Disciplina.objects.create(aluno=self.aluno, nome='Cálculo I')
        self.tarefa = TarefaDisciplina.objects.create(
            disciplina=self.disciplina,
            titulo='Resolver lista 1',
            prazo=timezone.now() + timezone.timedelta(days=3),
        )

    def test_endpoint_exige_autenticacao(self):
        response = self.client.get('/api/tarefas-disciplina/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_listar_tarefas_autenticado(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.get('/api/tarefas-disciplina/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        ids = [item['id'] for item in response.data]
        self.assertIn(str(self.tarefa.id), ids)

    def test_criar_tarefa(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.post('/api/tarefas-disciplina/', {
            'disciplina': str(self.disciplina.id),
            'titulo': 'Nova Tarefa',
            'prazo': (timezone.now() + timezone.timedelta(days=7)).isoformat(),
            'prioridade': Prioridade.ALTA,
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(TarefaDisciplina.objects.filter(titulo='Nova Tarefa').exists())

    def test_marcar_tarefa_como_concluida(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.patch(f'/api/tarefas-disciplina/{self.tarefa.id}/', {'concluida': True})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.tarefa.refresh_from_db()
        self.assertTrue(self.tarefa.concluida)

    def test_excluir_tarefa(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.delete(f'/api/tarefas-disciplina/{self.tarefa.id}/')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(TarefaDisciplina.objects.filter(id=self.tarefa.id).exists())
