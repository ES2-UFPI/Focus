from django.core.exceptions import ValidationError
from django.test import TestCase
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.test import APITestCase

from alunos.models import Aluno


class AlunoModelTests(TestCase):

    def test_create_user_seta_username_igual_email(self):
        aluno = Aluno.objects.create_user(
            email='aluno@teste.com',
            nome='Aluno Teste',
            password='senha123'
        )
        self.assertEqual(aluno.username, 'aluno@teste.com')
        self.assertTrue(aluno.check_password('senha123'))

    def test_create_user_sem_email_levanta_erro(self):
        with self.assertRaises(ValueError):
            Aluno.objects.create_user(email='', nome='Sem Email', password='senha123')

    def test_create_superuser_define_flags(self):
        admin = Aluno.objects.create_superuser(
            email='admin@teste.com',
            nome='Admin',
            password='senha123'
        )
        self.assertTrue(admin.is_staff)
        self.assertTrue(admin.is_superuser)

    def test_save_preenche_username_quando_ausente(self):
        aluno = Aluno(nome='Sem Username', email='sem-username@teste.com')
        aluno.set_password('senha123')
        aluno.save()
        self.assertEqual(aluno.username, 'sem-username@teste.com')

    def test_email_duplicado_e_invalido(self):
        Aluno.objects.create_user(email='dup@teste.com', nome='Primeiro', password='senha123')
        duplicado = Aluno(nome='Segundo', email='dup@teste.com', username='outro-username')
        duplicado.set_password('senha123')
        with self.assertRaises(ValidationError):
            duplicado.full_clean()

    def test_str_retorna_nome(self):
        aluno = Aluno.objects.create_user(email='nome@teste.com', nome='Fulano', password='senha123')
        self.assertEqual(str(aluno), 'Fulano')


class AuthEndpointsTests(APITestCase):

    def test_registro_cria_aluno_e_retorna_token(self):
        response = self.client.post('/api/auth/registro/', {
            'nome': 'Novo Aluno',
            'email': 'novo@teste.com',
            'senha': 'senha123',
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('token', response.data)
        self.assertEqual(response.data['aluno']['email'], 'novo@teste.com')
        self.assertTrue(Aluno.objects.filter(email='novo@teste.com').exists())
        aluno = Aluno.objects.get(email='novo@teste.com')
        self.assertTrue(aluno.check_password('senha123'))

    def test_registro_com_senha_curta_falha(self):
        response = self.client.post('/api/auth/registro/', {
            'nome': 'Novo Aluno',
            'email': 'curta@teste.com',
            'senha': '123',
        })
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(Aluno.objects.filter(email='curta@teste.com').exists())

    def test_registro_com_email_duplicado_falha(self):
        Aluno.objects.create_user(email='existente@teste.com', nome='Existente', password='senha123')
        response = self.client.post('/api/auth/registro/', {
            'nome': 'Outro',
            'email': 'existente@teste.com',
            'senha': 'senha123',
        })
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_login_com_credenciais_corretas_retorna_token(self):
        aluno = Aluno.objects.create_user(email='login@teste.com', nome='Login Teste', password='senha123')
        response = self.client.post('/api/auth/login/', {
            'email': 'login@teste.com',
            'senha': 'senha123',
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('token', response.data)
        token = Token.objects.get(user=aluno)
        self.assertEqual(response.data['token'], token.key)

    def test_login_com_senha_incorreta_falha(self):
        Aluno.objects.create_user(email='login2@teste.com', nome='Login Teste', password='senha123')
        response = self.client.post('/api/auth/login/', {
            'email': 'login2@teste.com',
            'senha': 'senha_errada',
        })
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_login_com_email_inexistente_falha(self):
        response = self.client.post('/api/auth/login/', {
            'email': 'inexistente@teste.com',
            'senha': 'senha123',
        })
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_listar_alunos_exige_autenticacao(self):
        response = self.client.get('/api/alunos/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_listar_alunos_autenticado(self):
        aluno = Aluno.objects.create_user(email='autenticado@teste.com', nome='Autenticado', password='senha123')
        self.client.force_authenticate(user=aluno)
        response = self.client.get('/api/alunos/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
