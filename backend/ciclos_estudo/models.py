import uuid
from django.db import models
from alunos.models import Aluno
from disciplinas.models import Disciplina


class CicloEstudo(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    aluno = models.ForeignKey(Aluno, on_delete=models.CASCADE, related_name='ciclos_estudo')
    disciplina = models.ForeignKey(Disciplina, on_delete=models.CASCADE, related_name='ciclos_estudo')
    nome = models.CharField(max_length=255)
    descricao = models.TextField(blank=True, null=True)
    data_inicio = models.DateField()
    data_fim = models.DateField()
    ativo = models.BooleanField(default=True)

    class Meta:
        verbose_name = 'Ciclo de Estudo'
        verbose_name_plural = 'Ciclos de Estudo'

    def __str__(self):
        return f'{self.nome} ({self.data_inicio} - {self.data_fim})'
