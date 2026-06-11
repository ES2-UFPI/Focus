import uuid
from django.db import models
from alunos.models import Aluno


class Disciplina(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    aluno = models.ForeignKey(Aluno, on_delete=models.CASCADE, related_name='disciplinas')
    nome = models.CharField(max_length=255)
    codigo = models.CharField(max_length=50, blank=True, null=True)
    descricao = models.TextField(blank=True, null=True)
    cor = models.CharField(max_length=20, default='#2196F3')
    meta_horas_semanais = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    ativo = models.BooleanField(default=True)
    data_criacao = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Disciplina'
        verbose_name_plural = 'Disciplinas'

    def __str__(self):
        return f'{self.codigo} - {self.nome}' if self.codigo else self.nome