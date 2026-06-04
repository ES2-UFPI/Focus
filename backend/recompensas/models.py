import uuid
from django.db import models
from alunos.models import Aluno


class Recompensa(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    aluno = models.ForeignKey(Aluno, on_delete=models.CASCADE, related_name='recompensas')
    titulo = models.CharField(max_length=255)
    descricao = models.TextField(blank=True, null=True)
    pontos_necessarios = models.IntegerField(default=0)
    resgatada = models.BooleanField(default=False)
    data_resgate = models.DateTimeField(blank=True, null=True)

    class Meta:
        verbose_name = 'Recompensa'
        verbose_name_plural = 'Recompensas'

    def __str__(self):
        return f'{self.titulo} - {self.aluno}'
