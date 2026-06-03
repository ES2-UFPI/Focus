import uuid
from django.db import models
from alunos.models import Aluno


class Disciplina(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    aluno = models.ForeignKey(Aluno, on_delete=models.CASCADE, related_name='disciplinas')
    nome = models.CharField(max_length=255)
    codigo = models.CharField(max_length=50, unique=True)
    descricao = models.TextField(blank=True, null=True)
    cor = models.CharField(max_length=20)
    carga_horaria_oficial = models.IntegerField()
    ativo = models.BooleanField(default=True)

    class Meta:
        verbose_name = 'Disciplina'
        verbose_name_plural = 'Disciplinas'

    def __str__(self):
        return f'{self.codigo} - {self.nome}'
