from django.contrib import admin

from .models import InsightFeedback


@admin.register(InsightFeedback)
class InsightFeedbackAdmin(admin.ModelAdmin):
    list_display = ('aluno', 'insight_id', 'tipo', 'util', 'criado_em')
    list_filter = ('util', 'tipo')
    search_fields = ('insight_id', 'tipo', 'aluno__email')
