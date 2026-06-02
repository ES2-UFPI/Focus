from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from avaliacoes_academicas.views import AvaliacaoAcademicaViewSet

router = DefaultRouter()
router.register(r'avaliacoes-academicas', AvaliacaoAcademicaViewSet)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
]
