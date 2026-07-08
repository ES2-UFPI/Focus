import uuid
from django.db import models
from django.core.exceptions import ValidationError
from django.core.validators import MaxValueValidator, MinValueValidator


class SemanaEstudo(models.Model):
    """
    Representa uma semana de estudo de um aluno (segunda a domingo).

    É a entidade "dona" do contexto temporal: toda SessaoEstudo e todo
    HorarioEstudo pertencem a uma SemanaEstudo específica. Isso permite
    histórico real, comparação entre semanas e evolução ao longo do tempo
    sem depender de cálculo de intervalo de datas em tempo de execução.

    Criada automaticamente pelo SemanaService — nunca manualmente pelo
    usuário ou pelo frontend.
    """

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    aluno = models.ForeignKey(
        'alunos.Aluno',
        on_delete=models.CASCADE,
        related_name='semanas_estudo'
    )

    data_inicio = models.DateField(
        help_text='Segunda-feira da semana, no horário local do aluno.'
    )

    data_fim = models.DateField(
        help_text='Domingo da semana, no horário local do aluno.'
    )

    ativa = models.BooleanField(
        default=True,
        help_text='True se esta é a semana corrente do aluno.'
    )

    criada_em = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Semana de Estudo'
        verbose_name_plural = 'Semanas de Estudo'
        ordering = ['-data_inicio']
        constraints = [
            models.UniqueConstraint(
                fields=['aluno', 'data_inicio'],
                name='unico_semana_por_aluno_e_inicio'
            ),
            models.CheckConstraint(
                check=models.Q(data_fim__gte=models.F('data_inicio')),
                name='semana_data_fim_apos_inicio'
            ),
        ]
        indexes = [
            models.Index(fields=['aluno', 'ativa']),
            models.Index(fields=['aluno', '-data_inicio']),
        ]

    def __str__(self):
        return f'{self.aluno_id} | {self.data_inicio} – {self.data_fim}'

    def clean(self):
        if self.data_fim < self.data_inicio:
            raise ValidationError('data_fim não pode ser anterior a data_inicio.')

    @property
    def numero_dias(self):
        return (self.data_fim - self.data_inicio).days + 1

    def contem_data(self, data) -> bool:
        """Verifica se uma data (date ou datetime) está dentro desta semana."""
        if hasattr(data, 'date'):
            data = data.date()
        return self.data_inicio <= data <= self.data_fim



class PlanejamentoDisciplina(models.Model):
    """
    Define a meta semanal de estudo para uma disciplina.

    Enquanto HorarioEstudo responde à pergunta:
        "Quando estudar?"

    PlanejamentoDisciplina responde:
        "Quanto estudar nesta semana?"

    Cada disciplina pode possuir apenas um planejamento por semana.
    """

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    semana_estudo = models.ForeignKey(
        SemanaEstudo,
        on_delete=models.CASCADE,
        related_name='planejamentos'
    )

    disciplina = models.ForeignKey(
        'disciplinas.Disciplina',
        on_delete=models.CASCADE,
        related_name='planejamentos_semanais'
    )

    carga_horaria_planejada = models.PositiveIntegerField(
        help_text='Carga horária planejada da semana, em minutos.'
    )

    observacoes = models.CharField(
        max_length=255,
        blank=True,
        null=True
    )

    criado_em = models.DateTimeField(auto_now_add=True)

    atualizado_em = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Planejamento da Disciplina'
        verbose_name_plural = 'Planejamento das Disciplinas'

        ordering = ['disciplina__nome']

        constraints = [

            # Uma disciplina só pode possuir um planejamento
            # por semana.
            models.UniqueConstraint(
                fields=['semana_estudo', 'disciplina'],
                name='planejamento_unico_por_semana'
            ),

            models.CheckConstraint(
                check=models.Q(carga_horaria_planejada__gt=0),
                name='planejamento_carga_positiva'
            ),
        ]

        indexes = [
            models.Index(fields=['semana_estudo']),
            models.Index(fields=['disciplina']),
        ]

    def __str__(self):
        horas = self.carga_horaria_planejada // 60
        minutos = self.carga_horaria_planejada % 60

        return (
            f'{self.disciplina.nome} - '
            f'{horas}h {minutos:02d}min'
        )

    def clean(self):
        super().clean()

        if self.disciplina.aluno_id != self.semana_estudo.aluno_id:
            raise ValidationError(
                'A disciplina não pertence ao aluno desta semana.'
            )

    @property
    def carga_horaria_horas(self):
        return round(self.carga_horaria_planejada / 60, 2)

    @property
    def total_realizado(self):
        """
        Soma os minutos realmente estudados
        para esta disciplina na semana.
        """
        return sum(
            self.semana_estudo.sessoes.filter(
                disciplina=self.disciplina,
                status=SessaoEstudo.StatusSessao.CONCLUIDO
            ).values_list(
                'duracao_realizada',
                flat=True
            )
        )

    @property
    def minutos_restantes(self):
        return max(
            0,
            self.carga_horaria_planejada - self.total_realizado
        )

    @property
    def percentual_concluido(self):
        if self.carga_horaria_planejada == 0:
            return 0

        return round(
            (self.total_realizado / self.carga_horaria_planejada) * 100,
            1
        )


class HorarioEstudo(models.Model):
    """
    Bloco de horário planejado para uma disciplina dentro de uma semana
    específica. Representa a INTENÇÃO de estudo, não o que de fato
    aconteceu — isso é papel da SessaoEstudo.

    Uma SessaoEstudo pode opcionalmente referenciar o HorarioEstudo que
    a originou, permitindo calcular taxa de aderência ao planejamento.
    """

    class DiaSemana(models.IntegerChoices):
        SEGUNDA = 0, 'Segunda-feira'
        TERCA = 1, 'Terça-feira'
        QUARTA = 2, 'Quarta-feira'
        QUINTA = 3, 'Quinta-feira'
        SEXTA = 4, 'Sexta-feira'
        SABADO = 5, 'Sábado'
        DOMINGO = 6, 'Domingo'

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    planejamento = models.ForeignKey(
        PlanejamentoDisciplina,
        on_delete=models.CASCADE,
        related_name='horarios',
        help_text='Planejamento semanal ao qual este horário pertence.'
    )
    
    
    @property
    def semana_estudo(self):
        return self.planejamento.semana_estudo


    @property
    def disciplina(self):
        return self.planejamento.disciplina

    dia_semana = models.IntegerField(choices=DiaSemana.choices)

    hora_inicio = models.TimeField()

    hora_fim = models.TimeField()

    ativo = models.BooleanField(default=True)

    criado_em = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Horário de Estudo'
        verbose_name_plural = 'Horários de Estudo'
        ordering = ['dia_semana', 'hora_inicio']
        constraints = [
            models.CheckConstraint(
                check=models.Q(hora_fim__gt=models.F('hora_inicio')),
                name='horario_fim_apos_inicio'
            ),
            models.UniqueConstraint(
                fields=['planejamento', 'dia_semana', 'hora_inicio', 'hora_fim'],
                name='horario_unico_por_planejamento'
            ),
        ]
        indexes = [
            models.Index(fields=['planejamento']),
            models.Index(fields=['dia_semana', 'hora_inicio']),
        ]

    def __str__(self):
        return (
            f'{self.disciplina.nome} | '
            f'{self.get_dia_semana_display()} '
            f'{self.hora_inicio:%H:%M} - {self.hora_fim:%H:%M}'
        )

    def clean(self):
        if self.hora_fim <= self.hora_inicio:
            raise ValidationError('hora_fim deve ser posterior a hora_inicio.')
        if (
            self.planejamento.disciplina.aluno_id
            !=
            self.planejamento.semana_estudo.aluno_id
        ):
            raise ValidationError(
                'O planejamento pertence a outro aluno.'
            )

    @property
    def duracao_minutos(self) -> int:
        """Duração planejada do bloco, em minutos."""
        inicio_min = self.hora_inicio.hour * 60 + self.hora_inicio.minute
        fim_min = self.hora_fim.hour * 60 + self.hora_fim.minute
        return fim_min - inicio_min


class SessaoEstudo(models.Model):
    """
    Representa o que realmente aconteceu: uma sessão de estudo concluída,
    agendada ou cancelada. Sempre vinculada a uma SemanaEstudo (preenchida
    automaticamente pelo backend) e opcionalmente a um HorarioEstudo,
    quando a sessão seguiu um bloco planejado.
    """

    class StatusSessao(models.TextChoices):
        AGENDADO = 'AGENDADO', 'Agendado'
        CONCLUIDO = 'CONCLUIDO', 'Concluído'
        CANCELADO = 'CANCELADO', 'Cancelado'

    class TipoAtividade(models.TextChoices):
        LEITURA = 'LEITURA', 'Leitura'
        EXERCICIO = 'EXERCICIO', 'Exercício'
        REVISAO = 'REVISAO', 'Revisão'

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    semana_estudo = models.ForeignKey(
        SemanaEstudo,
        on_delete=models.CASCADE,
        related_name='sessoes',
        editable=False,
        null=True,
        blank=True,
        help_text='Preenchido automaticamente pelo backend. Não enviado pelo cliente.'
    )

    disciplina = models.ForeignKey(
        'disciplinas.Disciplina',
        on_delete=models.CASCADE,
        related_name='sessoes_estudo'
    )

    horario_estudo = models.ForeignKey(
        HorarioEstudo,
        on_delete=models.SET_NULL,
        related_name='sessoes',
        null=True,
        blank=True,
        help_text='Bloco planejado que originou esta sessão, se houver.'
    )

    inicio = models.DateTimeField()

    fim = models.DateTimeField()

    duracao_realizada = models.PositiveIntegerField(
        default=0,
        help_text='Minutos efetivamente estudados (líquido, sem pausas).'
    )

    status = models.CharField(
        max_length=20,
        choices=StatusSessao.choices,
        default=StatusSessao.AGENDADO
    )

    descricao = models.CharField(max_length=255, blank=True, null=True)
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

    criada_em = models.DateTimeField(auto_now_add=True)
    atualizada_em = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Sessão de Estudo'
        verbose_name_plural = 'Sessões de Estudo'
        ordering = ['-inicio']
        constraints = [
            models.CheckConstraint(
                check=models.Q(fim__gt=models.F('inicio')),
                name='sessao_fim_apos_inicio'
            ),
        ]
        indexes = [
            models.Index(fields=['semana_estudo', 'status']),
            models.Index(fields=['disciplina', 'status']),
            models.Index(fields=['inicio']),
        ]

    def __str__(self):
        return f'{self.disciplina.nome} | {self.inicio:%d/%m %H:%M} ({self.status})'

    def clean(self):
        super().clean()

        # 1. Validar período (Essencial para qualquer sessão)
        if self.inicio and self.fim and self.fim <= self.inicio:
            raise ValidationError(
                'A data/hora de término deve ser posterior à data/hora de início.'
            )

        # 2. Validações que DEPENDEM da Semana de Estudo
        if self.semana_estudo_id:
            if self.disciplina and self.disciplina.aluno_id != self.semana_estudo.aluno_id:
                raise ValidationError(
                    'A disciplina deve pertencer ao mesmo aluno dono da semana de estudo.'
                )

            if self.horario_estudo and self.horario_estudo.disciplina_id != self.disciplina_id:
                raise ValidationError(
                    'O horário planejado pertence a uma disciplina diferente.'
                )

            if self.inicio and not self.semana_estudo.contem_data(self.inicio):
                raise ValidationError(
                    'O início da sessão está fora do período da semana vinculada.'
                )

        # 3. Validações de Conflito de Horário e Duplicidade (Devem rodar SEMPRE)
        if hasattr(self, 'disciplina') and self.disciplina:
            # Sessão duplicada
            duplicates = SessaoEstudo.objects.filter(
                disciplina=self.disciplina,
                inicio=self.inicio,
                fim=self.fim
            )
            if self.pk:
                duplicates = duplicates.exclude(pk=self.pk)
            if duplicates.exists():
                raise ValidationError("Já existe uma sessão de estudo cadastrada com estes mesmos horários para esta disciplina.")
            
            # Sobreposição de horários para o mesmo aluno
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
    @property
    def duracao_planejada_minutos(self) -> int:
        """Duração planejada do bloco (fim - inicio), em minutos."""
        return int((self.fim - self.inicio).total_seconds() / 60)

    @property
    def seguiu_planejamento(self) -> bool:
        return self.horario_estudo_id is not None


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
