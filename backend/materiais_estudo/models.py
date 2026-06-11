import uuid
from django.db import models
from alunos.models import Aluno
from disciplinas.models import Disciplina


TIPO_CHOICES = [
    ('PDF', 'PDF'),
    ('Resumo', 'Resumo'),
    ('Link', 'Link'),
    ('Video', 'Vídeo'),
    ('Outro', 'Outro'),
]


class MaterialEstudo(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    disciplina = models.ForeignKey(Disciplina, on_delete=models.CASCADE, related_name='materiais_estudo')
    titulo = models.CharField(max_length=255)
    tipo = models.CharField(max_length=20, choices=TIPO_CHOICES)
    url = models.URLField(blank=True, null=True)
    arquivo = models.FileField(upload_to='materiais/',blank=True,null=True)
    data_insercao = models.DateTimeField(auto_now_add=True)
    descricao = models.TextField(blank=True, null=True)

    class Meta:
        verbose_name = 'Material de Estudo'
        verbose_name_plural = 'Materiais de Estudo'

    def __str__(self):
        return f'{self.titulo} ({self.tipo})'
