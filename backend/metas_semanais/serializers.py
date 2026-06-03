from rest_framework import serializers
from .models import MetaSemanal


class MetaSemanalSerializer(serializers.ModelSerializer):
    class Meta:
        model = MetaSemanal
        fields = '__all__'
