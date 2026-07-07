from rest_framework import serializers

from .models import InsightFeedback


class InsightFeedbackInputSerializer(serializers.Serializer):
    """Valida o corpo de `POST /api/insights/{id}/feedback`.

    Aceita tanto `util` (bool) quanto o par frontend `useful`/`reason`.
    """

    util = serializers.BooleanField(required=False)
    useful = serializers.BooleanField(required=False)
    motivo = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    reason = serializers.CharField(required=False, allow_blank=True, allow_null=True)

    def validate(self, attrs):
        if 'util' not in attrs and 'useful' not in attrs:
            raise serializers.ValidationError(
                {'util': 'Informe se o insight foi útil (útil/useful).'}
            )
        attrs['util'] = attrs.get('util', attrs.get('useful'))
        attrs['motivo'] = attrs.get('motivo') or attrs.get('reason') or ''
        return attrs


class InsightFeedbackSerializer(serializers.ModelSerializer):
    class Meta:
        model = InsightFeedback
        fields = ['id', 'insight_id', 'tipo', 'util', 'motivo', 'criado_em']
        read_only_fields = fields
