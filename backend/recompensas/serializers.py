from rest_framework import serializers
from .models import Recompensa


class RecompensaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recompensa
        fields = '__all__'
