from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers

from .models import EventoAcademico


class EventoAcademicoSerializer(serializers.ModelSerializer):
    dias_restantes = serializers.ReadOnlyField()
    urgencia = serializers.ReadOnlyField()

    class Meta:
        model = EventoAcademico
        fields = '__all__'

    def validate(self, attrs):
        instance = self.instance
        if instance:
            for field, value in attrs.items():
                setattr(instance, field, value)
        else:
            # Create a temporary instance to validate
            instance = EventoAcademico(**attrs)
        
        try:
            instance.clean()
        except DjangoValidationError as e:
            raise serializers.ValidationError(e.message_dict if hasattr(e, 'message_dict') else e.messages)
        
        return attrs