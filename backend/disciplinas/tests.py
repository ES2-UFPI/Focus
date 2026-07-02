from rest_framework import status
from rest_framework.test import APITestCase

from alunos.models import Aluno
from disciplinas.models import Disciplina


class DisciplinaModelTests(APITestCase):

    def setUp(self):
        self.aluno = Aluno.objects.create_user(email='aluno@teste.com', nome='Aluno', password='senha123')

    def test_str_com_codigo(self):
        disciplina = Disciplina.objects.create(aluno=self.aluno, nome='Cálculo I', codigo='MAT101')
        self.assertEqual(str(disciplina), 'MAT101 - Cálculo I')

    def test_str_sem_codigo(self):
        disciplina = Disciplina.objects.create(aluno=self.aluno, nome='Cálculo I')
        self.assertEqual(str(disciplina), 'Cálculo I')

    def test_valores_padrao(self):
        disciplina = Disciplina.objects.create(aluno=self.aluno, nome='Física I')
        self.assertEqual(disciplina.cor, '#2196F3')
        self.assertEqual(disciplina.meta_horas_semanais, 0)
        self.assertTrue(disciplina.ativo)


class DisciplinaAPITests(APITestCase):

    def setUp(self):
        self.aluno = Aluno.objects.create_user(email='aluno@teste.com', nome='Aluno', password='senha123')
        self.outro_aluno = Aluno.objects.create_user(email='outro@teste.com', nome='Outro', password='senha123')
        self.disciplina = Disciplina.objects.create(aluno=self.aluno, nome='Cálculo I', codigo='MAT101')
        self.disciplina_outro = Disciplina.objects.create(aluno=self.outro_aluno, nome='Física I')

    def test_endpoint_exige_autenticacao(self):
        response = self.client.get('/api/disciplinas/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_listar_retorna_apenas_disciplinas_do_aluno_logado(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.get('/api/disciplinas/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        ids = [item['id'] for item in response.data]
        self.assertIn(str(self.disciplina.id), ids)
        self.assertNotIn(str(self.disciplina_outro.id), ids)

    def test_criar_disciplina_associa_aluno_autenticado(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.post('/api/disciplinas/', {
            'nome': 'Banco de Dados',
            'codigo': 'BD101',
            'meta_horas_semanais': 4,
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        nova = Disciplina.objects.get(id=response.data['id'])
        self.assertEqual(nova.aluno, self.aluno)

    def test_criar_disciplina_ignora_aluno_enviado_no_payload(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.post('/api/disciplinas/', {
            'nome': 'Redes',
            'aluno': str(self.outro_aluno.id),
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        nova = Disciplina.objects.get(id=response.data['id'])
        self.assertEqual(nova.aluno, self.aluno)

    def test_nao_pode_acessar_disciplina_de_outro_aluno(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.get(f'/api/disciplinas/{self.disciplina_outro.id}/')
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_atualizar_disciplina_propria(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.patch(f'/api/disciplinas/{self.disciplina.id}/', {'nome': 'Cálculo II'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.disciplina.refresh_from_db()
        self.assertEqual(self.disciplina.nome, 'Cálculo II')

    def test_excluir_disciplina_de_outro_aluno_nao_e_permitido(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.delete(f'/api/disciplinas/{self.disciplina_outro.id}/')
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
        self.assertTrue(Disciplina.objects.filter(id=self.disciplina_outro.id).exists())

    def test_excluir_disciplina_propria(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.delete(f'/api/disciplinas/{self.disciplina.id}/')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Disciplina.objects.filter(id=self.disciplina.id).exists())
