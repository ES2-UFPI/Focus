import uuid
from django.db import models
from django.core.exceptions import ValidationError
from django.core.validators import MaxValueValidator, MinValueValidator
from disciplinas.models import Disciplina
from eventos_academicos.models import EventoAcademico


class SessaoEstudo(models.Model):

    class StatusSessao(models.TextChoices):
        AGENDADO = 'AGENDADO', 'Agendado'
        EM_ANDAMENTO = 'EM_ANDAMENTO', 'Em Andamento'  #
        CONCLUIDO = 'CONCLUIDO', 'Concluído'          #
        CANCELADO = 'CANCELADO', 'Cancelado'

    class TipoAtividade(models.TextChoices):
        LEITURA = 'LEITURA', 'Leitura'
        EXERCICIO = 'EXERCICIO', 'Exercício'
        REVISAO = 'REVISAO', 'Revisão'

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
    energia_inicial = models.PositiveSmallIntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text='Energia/disposição informada antes da sessão (1 a 5).',
    )
    interrupcoes = models.PositiveIntegerField(
        default=0,
        help_text='Quantidade de interrupções registradas durante a sessão.',
    )
    tipo_atividade = models.CharField(
        max_length=10,
        choices=TipoAtividade.choices,
        null=True,
        blank=True,
        help_text='Método principal usado na sessão.',
    )

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
            
            # 2. Sessão duplicada (🔥 CORRIGIDO AQUI)
            if hasattr(self, 'disciplina') and self.disciplina:
                duplicates = SessaoEstudo.objects.filter(
                    disciplina=self.disciplina,
                    inicio=self.inicio,
                    fim=self.fim
                )
                
                # Garante de forma robusta que estamos editando a mesma sessão
                if self.id is not None:
                    duplicates = duplicates.exclude(id=self.id)
                    
                if duplicates.exists():
                    raise ValidationError("Já existe uma sessão de estudo cadastrada com estes mesmos horários para esta disciplina.")
                
                # 3. Sobreposição de horários para o mesmo aluno
                aluno = self.disciplina.aluno
                overlapping = SessaoEstudo.objects.filter(
                    disciplina__aluno=aluno,
                    inicio__lt=self.fim,
                    fim__gt=self.inicio
                )
                
                # Garante de forma robusta que não vai conflitar com ela mesma na edição
                if self.id is not None:
                    overlapping = overlapping.exclude(id=self.id)
                    
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


class BlocoPomodoro(models.Model):

    class StatusBloco(models.TextChoices):
        CONCLUIDO = 'CONCLUIDO', 'Concluído'
        ENCERRADO_ANTECIPADAMENTE = (
            'ENCERRADO_ANTECIPADAMENTE',
            'Encerrado antecipadamente',
        )
        INCOMPLETO = 'INCOMPLETO', 'Incompleto'

    class NivelProdutividade(models.IntegerChoices):
        MUITO_BAIXA = 1, 'Muito baixa'
        BAIXA = 2, 'Baixa'
        REGULAR = 3, 'Regular'
        ALTA = 4, 'Alta'
        MUITO_ALTA = 5, 'Muito alta'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    sessao_estudo = models.ForeignKey(
        SessaoEstudo,
        on_delete=models.CASCADE,
        related_name='blocos_pomodoro',
    )
    numero_ciclo = models.PositiveSmallIntegerField()
    inicio = models.DateTimeField()
    fim = models.DateTimeField()
    duracao_planejada_segundos = models.PositiveIntegerField()
    duracao_realizada_segundos = models.PositiveIntegerField()
    interrupcoes = models.PositiveIntegerField(default=0)
    status = models.CharField(
        max_length=30,
        choices=StatusBloco.choices,
    )
    produtividade = models.PositiveSmallIntegerField(
        choices=NivelProdutividade.choices,
        null=True,
        blank=True,
        help_text='Avaliação opcional de produtividade do bloco (1 a 5).',
    )
    data_criacao = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Bloco Pomodoro'
        verbose_name_plural = 'Blocos Pomodoro'
        ordering = ['-inicio']
        constraints = [
            models.CheckConstraint(
                condition=(
                    models.Q(status__in=[
                        'CONCLUIDO',
                        'ENCERRADO_ANTECIPADAMENTE',
                    ]) |
                    models.Q(produtividade__isnull=True)
                ),
                name='bloco_incompleto_sem_produtividade',
            ),
        ]

    def __str__(self):
        return (
            f'{self.sessao_estudo_id} - ciclo {self.numero_ciclo} '
            f'[{self.get_status_display()}]'
        )
