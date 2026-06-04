from rest_framework import serializers
from .models import FeedbackSessao


class FeedbackSessaoSerializer(serializers.ModelSerializer):
    class Meta:
        model = FeedbackSessao
        fields = '__all__'
