import uuid
from django.db import models
from alunos.models import Aluno
from sessoes_estudo.models import SessaoEstudo


NIVEL_DIFICULDADE_CHOICES = [
    ('Baixa', 'Baixa'),
    ('Media', 'Media'),
    ('Alta', 'Alta'),
]


class FeedbackSessao(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    sessao_estudo = models.ForeignKey(SessaoEstudo, on_delete=models.CASCADE, related_name='feedbacks_sessao')
    aluno = models.ForeignKey(Aluno, on_delete=models.CASCADE, related_name='feedbacks_sessao')
    nota_foco = models.IntegerField()
    nivel_dificuldade = models.CharField(max_length=10, choices=NIVEL_DIFICULDADE_CHOICES, default='Media')
    comentario = models.TextField(blank=True, null=True)
    data_feedback = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Feedback de Sessao'
        verbose_name_plural = 'Feedbacks de Sessao'

    def __str__(self):
        return f'{self.aluno} - {self.sessao_estudo} ({self.nota_foco})'
