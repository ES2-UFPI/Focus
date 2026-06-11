import uuid
import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('alunos', '0001_initial'),
        ('disciplinas', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='MaterialEstudo',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('titulo', models.CharField(max_length=255)),
                ('tipo', models.CharField(choices=[('PDF', 'PDF'), ('Resumo', 'Resumo'), ('Link', 'Link'), ('Video', 'Vídeo'), ('Outro', 'Outro')], max_length=20)),
                ('url', models.CharField(blank=True, max_length=500, null=True)),
                ('arquivo_path', models.CharField(blank=True, max_length=500, null=True)),
                ('data_insercao', models.DateTimeField(auto_now_add=True)),
                ('descricao', models.TextField(blank=True, null=True)),
                ('aluno', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='materiais_estudo', to='alunos.aluno')),
                ('disciplina', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='materiais_estudo', to='disciplinas.disciplina')),
            ],
            options={
                'verbose_name': 'Material de Estudo',
                'verbose_name_plural': 'Materiais de Estudo',
            },
        ),
    ]
