import uuid

from django.conf import settings
from django.db import models


class InsightFeedback(models.Model):
    """Feedback determinístico do aluno sobre um insight.

    Não alimenta nenhum modelo de ML: serve para personalização por regra —
    um insight marcado como "não útil" é rebaixado/ocultado nas próximas
    listagens daquele aluno (ver `InsightsService`).
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    aluno = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='insights_feedback',
    )
    # Identificador estável do insight (o mesmo devolvido em `Insight.id` e usado
    # na rota `POST /api/insights/{id}/feedback`). Ex.: "melhor_horario" ou
    # "ritmo_disciplina:<disciplina_id>".
    insight_id = models.CharField(max_length=120)
    # Tipo base do insight (sem o sufixo de disciplina), útil para agregações.
    tipo = models.CharField(max_length=60)
    util = models.BooleanField(
        help_text='True se o aluno marcou o insight como útil (👍), False se rejeitou (👎).',
    )
    motivo = models.TextField(blank=True, null=True)
    criado_em = models.DateTimeField(auto_now_add=True)
    atualizado_em = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Feedback de Insight'
        verbose_name_plural = 'Feedbacks de Insight'
        ordering = ['-criado_em']
        constraints = [
            models.UniqueConstraint(
                fields=['aluno', 'insight_id'],
                name='insightfeedback_unico_por_aluno_e_insight',
            ),
        ]

    def __str__(self):
        marca = '👍' if self.util else '👎'
        return f'{self.aluno_id} · {self.insight_id} {marca}'
