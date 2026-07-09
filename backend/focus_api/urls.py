from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from alunos.views import AlunoViewSet, registro, login
from disciplinas.views import DisciplinaViewSet
from tarefas_disciplina.views import TarefaDisciplinaViewSet
from materiais_estudo.views import MaterialEstudoViewSet
from eventos_academicos.views import EventoAcademicoViewSet, AgendaView
from sessao_estudo.views import BlocoPomodoroViewSet, SessaoEstudoViewSet
from feedback_sessao_estudo.views import FeedbackSessaoEstudoViewSet


router = DefaultRouter()


router.register(r'alunos', AlunoViewSet)
router.register(r'disciplinas', DisciplinaViewSet, basename='disciplina')
router.register(r'tarefas-disciplina', TarefaDisciplinaViewSet)
router.register(r'materiais-estudo', MaterialEstudoViewSet, basename='materialestudo')
router.register(r'eventos-academicos', EventoAcademicoViewSet, basename='eventoacademico')
router.register(r'sessoes-estudo', SessaoEstudoViewSet)
router.register(r'blocos-pomodoro', BlocoPomodoroViewSet, basename='blocopomodoro')
router.register(r'feedbacks-sessao', FeedbackSessaoEstudoViewSet)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/registro/', registro, name='registro'),
    path('api/auth/login/', login, name='login'),
    path('api/agenda/', AgendaView.as_view(), name='agenda'),
    path('api/', include('insights.urls')),
    path('api/', include(router.urls)),
]
