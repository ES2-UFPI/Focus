from django.core.exceptions import ValidationError as DjangoValidationError
from django.utils import timezone
from rest_framework import serializers

from .models import SessaoEstudo


class SessaoEstudoSerializer(serializers.ModelSerializer):
    """Serializer para mapear os dados da sessao de estudo para JSON."""

    disciplina_nome = serializers.CharField(source='disciplina.nome', read_only=True)
    semana_estudo = serializers.SerializerMethodField()
    horario_estudo = serializers.SerializerMethodField()

    class Meta:
        model = SessaoEstudo
        fields = [
            'id',
            'semana_estudo',
            'disciplina',
            'disciplina_nome',
            'horario_estudo',
            'inicio',
            'fim',
            'duracao_realizada',
            'status',
            'descricao',
        ]
        read_only_fields = [
            'id',
            'semana_estudo',
            'horario_estudo',
            'duracao_realizada',
        ]

    def get_semana_estudo(self, obj):
        return timezone.localtime(obj.inicio).isocalendar().week

    def get_horario_estudo(self, obj):
        inicio = timezone.localtime(obj.inicio).strftime('%H:%M')
        fim = timezone.localtime(obj.fim).strftime('%H:%M')
        return f'{inicio} - {fim}'

    def validate(self, attrs):
        instance = self.instance
        if instance:
            for field, value in attrs.items():
                setattr(instance, field, value)
        else:
            instance = SessaoEstudo(**attrs)

        try:
            instance.clean()
        except DjangoValidationError as e:
            raise serializers.ValidationError(
                e.message_dict if hasattr(e, 'message_dict') else e.messages
            )

        return attrs
