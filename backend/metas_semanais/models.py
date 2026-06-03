import uuid
from django.db import models
from alunos.models import Aluno
from disciplinas.models import Disciplina


class MetaSemanal(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    aluno = models.ForeignKey(Aluno, on_delete=models.CASCADE, related_name='metas_semanais')
    disciplina = models.ForeignKey(Disciplina, on_delete=models.CASCADE, related_name='metas_semanais')
    horas_planejadas = models.DecimalField(max_digits=5, decimal_places=2)
    data_inicio = models.DateField()
    data_fim = models.DateField()
    ativa = models.BooleanField(default=True)

    class Meta:
        verbose_name = 'Meta Semanal'
        verbose_name_plural = 'Metas Semanais'

    def __str__(self):
        return f'{self.aluno} - {self.disciplina} ({self.data_inicio} a {self.data_fim})'
