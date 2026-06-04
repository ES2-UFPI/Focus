import django.db.models.deletion
import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('disciplinas', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='SessaoEstudo',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('data_inicio', models.DateTimeField()),
                ('data_fim', models.DateTimeField(blank=True, null=True)),
                ('duracao_minutos', models.IntegerField(blank=True, null=True)),
                ('concluida', models.BooleanField(default=False)),
                ('observacao', models.TextField(blank=True, null=True)),
                ('aluno', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='sessoes_estudo', to=settings.AUTH_USER_MODEL)),
                ('disciplina', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='sessoes_estudo', to='disciplinas.disciplina')),
            ],
            options={
                'verbose_name': 'Sessao de Estudo',
                'verbose_name_plural': 'Sessoes de Estudo',
            },
        ),
    ]
