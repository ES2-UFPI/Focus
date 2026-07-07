from rest_framework import serializers

from .models import BlocoPomodoro, SemanaEstudo, PlanejamentoDisciplina, HorarioEstudo, SessaoEstudo

# ──────────────────────────────────────────────
# SemanaEstudo
# ──────────────────────────────────────────────

class SemanaEstudoSerializer(serializers.ModelSerializer):
    numero_dias = serializers.IntegerField(read_only=True)

    class Meta:
        model = SemanaEstudo
        fields = [
            'id',
            'data_inicio',
            'data_fim',
            'ativa',
            'numero_dias',
            'criada_em',
        ]
        read_only_fields = fields


# ──────────────────────────────────────────────
# PlanejamentoDisciplina
# ──────────────────────────────────────────────

class PlanejamentoDisciplinaSerializer(serializers.ModelSerializer):
    disciplina_nome = serializers.CharField(
        source='disciplina.nome',
        read_only=True
    )

    carga_horaria_horas = serializers.FloatField(read_only=True)
    total_realizado = serializers.IntegerField(read_only=True)
    minutos_restantes = serializers.IntegerField(read_only=True)
    percentual_concluido = serializers.FloatField(read_only=True)

    class Meta:
        model = PlanejamentoDisciplina
        fields = [
            'id',
            'semana_estudo',
            'disciplina',
            'disciplina_nome',
            'carga_horaria_planejada',
            'carga_horaria_horas',
            'total_realizado',
            'minutos_restantes',
            'percentual_concluido',
            'observacoes',
            'criado_em',
            'atualizado_em',
        ]

        read_only_fields = [
            'id',
            'semana_estudo',
            'disciplina_nome',
            'carga_horaria_horas',
            'total_realizado',
            'minutos_restantes',
            'percentual_concluido',
            'criado_em',
            'atualizado_em',
        ]

    def validate(self, attrs):
        disciplina = attrs.get(
            'disciplina',
            getattr(self.instance, 'disciplina', None)
        )

        request = self.context.get('request')

        if disciplina and request and disciplina.aluno_id != request.user.id:
            raise serializers.ValidationError({
                'disciplina': 'Você não pode utilizar esta disciplina.'
            })

        carga = attrs.get(
            'carga_horaria_planejada',
            getattr(self.instance, 'carga_horaria_planejada', 0)
        )

        if carga <= 0:
            raise serializers.ValidationError({
                'carga_horaria_planejada':
                'A carga horária deve ser maior que zero.'
            })

        return attrs


# ──────────────────────────────────────────────
# HorarioEstudo
# ──────────────────────────────────────────────

class HorarioEstudoSerializer(serializers.ModelSerializer):

    dia_semana_label = serializers.CharField(
        source='get_dia_semana_display',
        read_only=True
    )

    disciplina = serializers.SerializerMethodField()
    disciplina_nome = serializers.SerializerMethodField()

    semana_estudo = serializers.SerializerMethodField()

    duracao_minutos = serializers.IntegerField(read_only=True)

    class Meta:
        model = HorarioEstudo
        fields = [
            'id',
            'planejamento',
            'semana_estudo',
            'disciplina',
            'disciplina_nome',
            'dia_semana',
            'dia_semana_label',
            'hora_inicio',
            'hora_fim',
            'duracao_minutos',
            'ativo',
            'criado_em',
        ]

        read_only_fields = [
            'id',
            'semana_estudo',
            'disciplina',
            'disciplina_nome',
            'criado_em',
        ]

    def get_disciplina(self, obj):
        return str(obj.disciplina.id)

    def get_disciplina_nome(self, obj):
        return obj.disciplina.nome

    def get_semana_estudo(self, obj):
        return str(obj.semana_estudo.id)

    def validate(self, attrs):

        hora_inicio = attrs.get(
            'hora_inicio',
            getattr(self.instance, 'hora_inicio', None)
        )

        hora_fim = attrs.get(
            'hora_fim',
            getattr(self.instance, 'hora_fim', None)
        )

        if hora_inicio and hora_fim and hora_fim <= hora_inicio:
            raise serializers.ValidationError({
                'hora_fim':
                'Deve ser posterior à hora de início.'
            })

        planejamento = attrs.get(
            'planejamento',
            getattr(self.instance, 'planejamento', None)
        )

        request = self.context.get('request')

        if (
            planejamento
            and request
            and planejamento.disciplina.aluno_id != request.user.id
        ):
            raise serializers.ValidationError({
                'planejamento':
                'Este planejamento pertence a outro aluno.'
            })

        return attrs


# ──────────────────────────────────────────────
# SessaoEstudo
# ──────────────────────────────────────────────

class SessaoEstudoSerializer(serializers.ModelSerializer):

    disciplina_nome = serializers.CharField(
        source='disciplina.nome',
        read_only=True
    )

    semana_estudo_detalhes = SemanaEstudoSerializer(
        source='semana_estudo',
        read_only=True
    )

    duracao_planejada_minutos = serializers.IntegerField(
        read_only=True
    )

    seguiu_planejamento = serializers.BooleanField(
        read_only=True
    )

    class Meta:
        model = SessaoEstudo

        fields = [
            'id',
            'semana_estudo',
            'semana_estudo_detalhes',
            'disciplina',
            'disciplina_nome',
            'horario_estudo',
            'inicio', 
            'fim', 
            'duracao_realizada', 
            'status',
            'descricao',
            'energia_inicial',
            'interrupcoes',
            'tipo_atividade',
        ]
      
        read_only_fields = ['id', 'semana_estudo']
        
    def get_semana_estudo(self, obj):
        return timezone.localtime(obj.inicio).isocalendar().week

    def get_horario_estudo(self, obj):
        inicio = timezone.localtime(obj.inicio).strftime('%H:%M')
        fim = timezone.localtime(obj.fim).strftime('%H:%M')
        return f'{inicio} - {fim}'

    def validate(self, attrs):
        # Criamos um dicionário temporário a partir dos dados já validados/tratados pelo DRF
        contexto_validacao = {}
        
        if self.instance:
            contexto_validacao = {
                'id': self.instance.id, # 🌟 ADICIONE ESTA LINHA AQUI! (Injeta o UUID na validação)
                'disciplina_id': self.instance.disciplina_id,
                'inicio': self.instance.inicio,
                'fim': self.instance.fim,
                'status': self.instance.status,
                'duracao_realizada': self.instance.duracao_realizada,
                'descricao': self.instance.descricao,
                'energia_inicial': self.instance.energia_inicial,
                'interrupcoes': self.instance.interrupcoes,
                'tipo_atividade': self.instance.tipo_atividade,
            }
            
        # Mescla estritamente com os novos dados modificados vindos do payload
        for campo, valor in attrs.items():
            if campo == 'disciplina':
                contexto_validacao['disciplina_id'] = valor.id if hasattr(valor, 'id') else valor
            else:
                contexto_validacao[campo] = valor

        # Criamos o objeto temporário de forma segura repassando o ID
        try:
            temp_instance = SessaoEstudo(**contexto_validacao)
            temp_instance.clean()
        except DjangoValidationError as e:
            raise serializers.ValidationError(
                e.message_dict if hasattr(e, 'message_dict') else e.messages
            )

        return attrs

class BlocoPomodoroSerializer(serializers.ModelSerializer):

    class Meta:
        model = BlocoPomodoro
        fields = [
            'id',
            'sessao_estudo',
            'numero_ciclo',
            'inicio',
            'fim',
            'duracao_planejada_segundos',
            'duracao_realizada_segundos',
            'interrupcoes',
            'status',
            'produtividade',
            'data_criacao',
        ]
        read_only_fields = ['id', 'data_criacao']

    def validate(self, attrs):
        instance = self.instance
        sessao = attrs.get(
            'sessao_estudo',
            instance.sessao_estudo if instance else None,
        )
        status_bloco = attrs.get(
            'status',
            instance.status if instance else None,
        )
        produtividade = attrs.get(
            'produtividade',
            instance.produtividade if instance else None,
        )
        inicio = attrs.get('inicio', instance.inicio if instance else None)
        fim = attrs.get('fim', instance.fim if instance else None)

        request = self.context.get('request')
        if (
            request is not None
            and sessao is not None
            and sessao.disciplina.aluno_id != request.user.id
        ):
            raise serializers.ValidationError({
                'sessao_estudo': 'Você não tem permissão para usar esta sessão.'
            })

        if (
            status_bloco == BlocoPomodoro.StatusBloco.INCOMPLETO
            and produtividade is not None
        ):
            raise serializers.ValidationError({
                'produtividade': 'Um bloco incompleto não pode ser avaliado.'
            })

        if inicio is not None and fim is not None and fim < inicio:
            raise serializers.ValidationError({
                'fim': 'O término não pode ser anterior ao início do bloco.'
            })

        return attrs
