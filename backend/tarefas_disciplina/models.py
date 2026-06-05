import uuid
from django.db import models

from disciplinas.models import Disciplina
from eventos_academicos.models import EventoAcademico


class Prioridade(models.TextChoices):
    BAIXA = 'BAIXA', 'Baixa'
    MEDIA = 'MEDIA', 'Média'
    ALTA = 'ALTA', 'Alta'


class TarefaDisciplina(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    disciplina = models.ForeignKey(
        Disciplina,
        on_delete=models.CASCADE,
        related_name='tarefas'
    )

    evento = models.ForeignKey(
        EventoAcademico,
        on_delete=models.SET_NULL,
        related_name='tarefas',
        blank=True,
        null=True
    )

    titulo = models.CharField(max_length=255)
    descricao = models.TextField(blank=True, null=True)

    prazo = models.DateTimeField()

    concluida = models.BooleanField(default=False)

    data_conclusao = models.DateTimeField(blank=True, null=True)

    prioridade = models.CharField(
        max_length=10,
        choices=Prioridade.choices,
        default=Prioridade.MEDIA
    )

    class Meta:
        verbose_name = 'Tarefa de Disciplina'
        verbose_name_plural = 'Tarefas de Disciplina'
        ordering = ['prazo']

    def __str__(self):
        return str(self.titulo)