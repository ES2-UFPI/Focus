from rest_framework import serializers

from .models import FeedbackSessaoEstudo


class FeedbackSessaoEstudoSerializer(serializers.ModelSerializer):
   
    class Meta:
        model = FeedbackSessaoEstudo
        fields = '__all__'