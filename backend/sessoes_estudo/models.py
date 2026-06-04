import uuid
from django.db import models
from alunos.models import Aluno
from disciplinas.models import Disciplina


class SessaoEstudo(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    aluno = models.ForeignKey(Aluno, on_delete=models.CASCADE, related_name='sessoes_estudo')
    disciplina = models.ForeignKey(Disciplina, on_delete=models.CASCADE, related_name='sessoes_estudo')
    data_inicio = models.DateTimeField()
    data_fim = models.DateTimeField(blank=True, null=True)
    duracao_minutos = models.IntegerField(blank=True, null=True)
    concluida = models.BooleanField(default=False)
    observacao = models.TextField(blank=True, null=True)

    class Meta:
        verbose_name = 'Sessao de Estudo'
        verbose_name_plural = 'Sessoes de Estudo'

    def __str__(self):
        return f'{self.aluno} - {self.disciplina} ({self.data_inicio})'
