from rest_framework import serializers
from .models import AvaliacaoAcademica


class AvaliacaoAcademicaSerializer(serializers.ModelSerializer):
    class Meta:
        model = AvaliacaoAcademica
        fields = '__all__'
