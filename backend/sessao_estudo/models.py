import uuid
from django.db import models
from disciplinas.models import Disciplina


class SessaoEstudo(models.Model):
 
    class StatusSessao(models.TextChoices):
        AGENDADO = 'AGENDADO', 'Agendado'
        EM_ANDAMENTO = 'EM_ANDAMENTO', 'Em Andamento'  # 
        CONCLUIDO = 'CONCLUIDO', 'Concluído'          # 
        CANCELADO = 'CANCELADO', 'Cancelado'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    disciplina = models.ForeignKey(
        Disciplina, 
        on_delete=models.CASCADE, 
        related_name='sessoes_estudo'
    )

    inicio = models.DateTimeField()
    fim = models.DateTimeField()
 
    duracao_realizada = models.PositiveIntegerField(
        default=0,
    )
    status = models.CharField(
        max_length=20,
        choices=StatusSessao.choices,
        default=StatusSessao.AGENDADO
    )
    descricao = models.TextField(blank=True, null=True)

    data_criacao = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Sessão de Estudo'
        verbose_name_plural = 'Sessões de Estudo'
        ordering = ['-inicio']

    def __str__(self):

        disciplina_txt = str(self.disciplina) if self.disciplina else "Sem Disciplina"
        status_txt = self.StatusSessao(self.status).label
        return f"{disciplina_txt} - Foco: {self.duracao_realizada}min [{status_txt}]"
  
 