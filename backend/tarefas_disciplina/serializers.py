from rest_framework import serializers
from .models import TarefaDisciplina


class TarefaDisciplinaSerializer(serializers.ModelSerializer):
    class Meta:
        model = TarefaDisciplina
        fields = '__all__'
