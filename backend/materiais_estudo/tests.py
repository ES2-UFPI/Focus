from rest_framework import status
from rest_framework.test import APITestCase

from alunos.models import Aluno
from disciplinas.models import Disciplina
from materiais_estudo.models import MaterialEstudo


class MaterialEstudoModelTests(APITestCase):

    def setUp(self):
        self.aluno = Aluno.objects.create_user(email='aluno@teste.com', nome='Aluno', password='senha123')
        self.disciplina = Disciplina.objects.create(aluno=self.aluno, nome='Cálculo I')

    def test_str_inclui_titulo_e_tipo(self):
        material = MaterialEstudo.objects.create(
            disciplina=self.disciplina,
            titulo='Lista de Exercícios 1',
            tipo='PDF',
        )
        self.assertEqual(str(material), 'Lista de Exercícios 1 (PDF)')


class MaterialEstudoAPITests(APITestCase):

    def setUp(self):
        self.aluno = Aluno.objects.create_user(email='aluno@teste.com', nome='Aluno', password='senha123')
        self.outro_aluno = Aluno.objects.create_user(email='outro@teste.com', nome='Outro', password='senha123')
        self.disciplina = Disciplina.objects.create(aluno=self.aluno, nome='Cálculo I')
        self.disciplina_outro = Disciplina.objects.create(aluno=self.outro_aluno, nome='Física I')
        self.material = MaterialEstudo.objects.create(
            disciplina=self.disciplina, titulo='Slides Aula 1', tipo='PDF'
        )
        self.material_video = MaterialEstudo.objects.create(
            disciplina=self.disciplina, titulo='Aula Gravada', tipo='Video'
        )
        self.material_outro = MaterialEstudo.objects.create(
            disciplina=self.disciplina_outro, titulo='Material de Outro Aluno', tipo='PDF'
        )

    def test_endpoint_exige_autenticacao(self):
        response = self.client.get('/api/materiais-estudo/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_listar_retorna_apenas_materiais_do_aluno_logado(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.get('/api/materiais-estudo/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        ids = [item['id'] for item in response.data]
        self.assertIn(str(self.material.id), ids)
        self.assertNotIn(str(self.material_outro.id), ids)

    def test_filtro_por_tipo(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.get('/api/materiais-estudo/', {'tipo': 'Video'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        ids = [item['id'] for item in response.data]
        self.assertEqual(ids, [str(self.material_video.id)])

    def test_filtro_por_disciplina(self):
        outra_disciplina = Disciplina.objects.create(aluno=self.aluno, nome='Física I')
        material_outra_disciplina = MaterialEstudo.objects.create(
            disciplina=outra_disciplina, titulo='Resumo Física', tipo='Resumo'
        )
        self.client.force_authenticate(user=self.aluno)
        response = self.client.get('/api/materiais-estudo/', {'disciplina': str(outra_disciplina.id)})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        ids = [item['id'] for item in response.data]
        self.assertEqual(ids, [str(material_outra_disciplina.id)])

    def test_busca_por_titulo(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.get('/api/materiais-estudo/', {'search': 'Slides'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        ids = [item['id'] for item in response.data]
        self.assertEqual(ids, [str(self.material.id)])

    def test_criar_material_para_disciplina_propria(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.post('/api/materiais-estudo/', {
            'titulo': 'Novo Material',
            'tipo': 'Link',
            'url': 'https://exemplo.com/material',
            'disciplina': str(self.disciplina.id),
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(MaterialEstudo.objects.filter(titulo='Novo Material').exists())

    def test_nao_pode_acessar_material_de_outro_aluno(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.get(f'/api/materiais-estudo/{self.material_outro.id}/')
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_excluir_material_proprio(self):
        self.client.force_authenticate(user=self.aluno)
        response = self.client.delete(f'/api/materiais-estudo/{self.material.id}/')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(MaterialEstudo.objects.filter(id=self.material.id).exists())
