from django.urls import path

from . import views

urlpatterns = [
    path('insights/', views.listar_insights, name='insights-listar'),
    path('insights/evolucao/', views.evolucao, name='insights-evolucao'),
    path(
        'insights/<str:insight_id>/feedback/',
        views.registrar_feedback,
        name='insights-feedback',
    ),
]
