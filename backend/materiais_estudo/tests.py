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


DESCRICAO_NOTA = (
    'Observações importantes:\n'
    '- Backlog precisa estar priorizado.\n'
    '\n'
    'Dicas para prova:\n'
    '- Saber explicar user story.'
)


class NotasApiTests(APITestCase):
    """Contrato da sessão de Notas do app.

    Uma "nota" é um MaterialEstudo com tipo='Resumo' e o conteúdo em texto
    legível (cabeçalhos de seção + itens) na descricao. A tela de Notas
    consome exatamente o que está garantido aqui.
    """

    ENDPOINT = '/api/materiais-estudo/'

    def setUp(self):
        self.aluno = Aluno.objects.create_user(
            email='nota@teste.com', nome='Estudante', password='senha123'
        )
        self.disciplina = Disciplina.objects.create(
            aluno=self.aluno, nome='Engenharia de Software II'
        )
        self.client.force_authenticate(user=self.aluno)

    def test_criar_nota_grava_conteudo_e_disciplina(self):
        response = self.client.post(self.ENDPOINT, {
            'titulo': 'Aula sobre requisitos e backlog',
            'tipo': 'Resumo',
            'disciplina': str(self.disciplina.id),
            'descricao': DESCRICAO_NOTA,
        })

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['tipo'], 'Resumo')
        self.assertEqual(response.data['descricao'], DESCRICAO_NOTA)
        self.assertEqual(response.data['disciplina'], self.disciplina.id)
        # Campos que a tela exibe sem o usuário digitar:
        self.assertEqual(
            response.data['disciplina_nome'], 'Engenharia de Software II'
        )
        self.assertIsNotNone(response.data['data_insercao'])

    def test_nota_sem_disciplina_e_rejeitada(self):
        response = self.client.post(self.ENDPOINT, {
            'titulo': 'Nota órfã',
            'tipo': 'Resumo',
            'descricao': DESCRICAO_NOTA,
        })
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_tela_de_notas_carrega_apenas_resumos(self):
        nota = MaterialEstudo.objects.create(
            disciplina=self.disciplina, titulo='Nota', tipo='Resumo',
            descricao=DESCRICAO_NOTA,
        )
        MaterialEstudo.objects.create(
            disciplina=self.disciplina, titulo='Slides', tipo='PDF',
        )

        response = self.client.get(self.ENDPOINT, {'tipo': 'Resumo'})

        ids = [item['id'] for item in response.data]
        self.assertEqual(ids, [str(nota.id)])

    def test_editar_nota_atualiza_titulo_e_secoes(self):
        nota = MaterialEstudo.objects.create(
            disciplina=self.disciplina, titulo='Rascunho', tipo='Resumo',
            descricao=DESCRICAO_NOTA,
        )

        response = self.client.patch(f'{self.ENDPOINT}{nota.id}/', {
            'titulo': 'Título revisado',
            'descricao': 'Conceitos-chave:\n- 1FN, 2FN, 3FN',
        })

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        nota.refresh_from_db()
        self.assertEqual(nota.titulo, 'Título revisado')
        self.assertEqual(nota.descricao, 'Conceitos-chave:\n- 1FN, 2FN, 3FN')

    def test_busca_encontra_nota_pelo_conteudo_das_secoes(self):
        MaterialEstudo.objects.create(
            disciplina=self.disciplina, titulo='Nota', tipo='Resumo',
            descricao=DESCRICAO_NOTA,
        )

        response = self.client.get(self.ENDPOINT, {'search': 'user story'})

        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['titulo'], 'Nota')
