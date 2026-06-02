import uuid
from django.db import models
from alunos.models import Aluno
from disciplinas.models import Disciplina


TIPO_CHOICES = [
    ('Prova', 'Prova'),
    ('Trabalho', 'Trabalho'),
    ('Seminario', 'Seminário'),
    ('Outro', 'Outro'),
]


class AvaliacaoAcademica(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    aluno = models.ForeignKey(Aluno, on_delete=models.CASCADE, related_name='avaliacoes_academicas')
    disciplina = models.ForeignKey(Disciplina, on_delete=models.CASCADE, related_name='avaliacoes_academicas')
    tipo = models.CharField(max_length=20, choices=TIPO_CHOICES)
    data = models.DateField()
    nota = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    peso = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    observacao = models.TextField(blank=True, null=True)

    class Meta:
        verbose_name = 'Avaliação Acadêmica'
        verbose_name_plural = 'Avaliações Acadêmicas'

    def __str__(self):
        return f'{self.tipo} - {self.disciplina} ({self.data})'
