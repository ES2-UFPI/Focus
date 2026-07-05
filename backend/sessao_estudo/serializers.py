from rest_framework import serializers

from .models import (
    SemanaEstudo,
    PlanejamentoDisciplina,
    HorarioEstudo,
    SessaoEstudo,
)


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
            'duracao_planejada_minutos',
            'seguiu_planejamento',
            'status',
            'descricao',
            'criada_em',
            'atualizada_em',
        ]

        read_only_fields = [
            'id',
            'semana_estudo',
            'criada_em',
            'atualizada_em',
        ]

    def validate(self, attrs):

        inicio = attrs.get(
            'inicio',
            getattr(self.instance, 'inicio', None)
        )

        fim = attrs.get(
            'fim',
            getattr(self.instance, 'fim', None)
        )

        if inicio and fim and fim <= inicio:
            raise serializers.ValidationError({
                'fim':
                'Deve ser posterior ao início.'
            })

        disciplina = attrs.get(
            'disciplina',
            getattr(self.instance, 'disciplina', None)
        )

        request = self.context.get('request')

        if (
            disciplina
            and request
            and disciplina.aluno_id != request.user.id
        ):
            raise serializers.ValidationError({
                'disciplina':
                'Você não pode utilizar esta disciplina.'
            })

        horario = attrs.get(
            'horario_estudo',
            getattr(self.instance, 'horario_estudo', None)
        )

        if (
            horario
            and disciplina
            and horario.disciplina.id != disciplina.id
        ):
            raise serializers.ValidationError({
                'horario_estudo':
                'O horário pertence a outra disciplina.'
            })

        status_sessao = attrs.get(
            'status',
            getattr(self.instance, 'status', None)
        )

        duracao = attrs.get(
            'duracao_realizada',
            getattr(self.instance, 'duracao_realizada', 0)
        )

        if (
            status_sessao == SessaoEstudo.StatusSessao.CONCLUIDO
            and duracao <= 0
        ):
            raise serializers.ValidationError({
                'duracao_realizada':
                'Informe a duração real da sessão concluída.'
            })

        return attrs