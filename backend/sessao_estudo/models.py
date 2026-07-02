import uuid
from django.db import models
from django.core.exceptions import ValidationError
from disciplinas.models import Disciplina
from eventos_academicos.models import EventoAcademico


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
    evento_academico = models.ForeignKey(
        EventoAcademico,
        on_delete=models.SET_NULL,
        related_name='sessoes_estudo',
        null=True,
        blank=True,
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

    def clean(self):
        super().clean()

        if self.evento_academico_id and self.disciplina_id and \
                self.evento_academico.disciplina_id != self.disciplina_id:
            raise ValidationError(
                "O evento acadêmico selecionado não pertence à disciplina desta sessão."
            )

        if self.inicio and self.fim:
            # 1. Validar período
            if self.fim <= self.inicio:
                raise ValidationError("A data/hora de término deve ser posterior à data/hora de início.")
            
            # 2. Sessão duplicada
            if hasattr(self, 'disciplina') and self.disciplina:
                duplicates = SessaoEstudo.objects.filter(
                    disciplina=self.disciplina,
                    inicio=self.inicio,
                    fim=self.fim
                )
                if self.pk:
                    duplicates = duplicates.exclude(pk=self.pk)
                if duplicates.exists():
                    raise ValidationError("Já existe uma sessão de estudo cadastrada com estes mesmos horários para esta disciplina.")
                
                # 3. Sobreposição de horários para o mesmo aluno
                aluno = self.disciplina.aluno
                overlapping = SessaoEstudo.objects.filter(
                    disciplina__aluno=aluno,
                    inicio__lt=self.fim,
                    fim__gt=self.inicio
                )
                if self.pk:
                    overlapping = overlapping.exclude(pk=self.pk)
                if overlapping.exists():
                    raise ValidationError("Conflito de agenda: Esta sessão de estudo coincide com outra sessão de estudo do aluno.")

    class Meta:
        verbose_name = 'Sessão de Estudo'
        verbose_name_plural = 'Sessões de Estudo'
        ordering = ['-inicio']

    def __str__(self):

        disciplina_txt = str(self.disciplina) if self.disciplina else "Sem Disciplina"
        status_txt = self.StatusSessao(self.status).label
        return f"{disciplina_txt} - Foco: {self.duracao_realizada}min [{status_txt}]"