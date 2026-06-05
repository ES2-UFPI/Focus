from rest_framework import serializers

from .models import EventoAcademico


class EventoAcademicoSerializer(serializers.ModelSerializer):
    class Meta:
        model = EventoAcademico
        fields = '__all__'