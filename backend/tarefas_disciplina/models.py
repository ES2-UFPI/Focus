import uuid
from django.db import models
from alunos.models import Aluno
from disciplinas.models import Disciplina


PRIORIDADE_CHOICES = [
    ('Baixa', 'Baixa'),
    ('Media', 'Média'),
    ('Alta', 'Alta'),
]


class TarefaDisciplina(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    aluno = models.ForeignKey(Aluno, on_delete=models.CASCADE, related_name='tarefas_disciplina')
    disciplina = models.ForeignKey(Disciplina, on_delete=models.CASCADE, related_name='tarefas_disciplina')
    titulo = models.CharField(max_length=255)
    descricao = models.TextField(blank=True, null=True)
    prazo = models.DateTimeField()
    concluida = models.BooleanField(default=False)
    data_conclusao = models.DateTimeField(blank=True, null=True)
    prioridade = models.CharField(max_length=10, choices=PRIORIDADE_CHOICES, default='Media')

    class Meta:
        verbose_name = 'Tarefa de Disciplina'
        verbose_name_plural = 'Tarefas de Disciplina'

    def __str__(self):
        return f'{self.titulo} - {self.disciplina}'
