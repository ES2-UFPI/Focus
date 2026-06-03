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
            name='CicloEstudo',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('nome', models.CharField(max_length=255)),
                ('descricao', models.TextField(blank=True, null=True)),
                ('data_inicio', models.DateField()),
                ('data_fim', models.DateField()),
                ('ativo', models.BooleanField(default=True)),
                ('aluno', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='ciclos_estudo', to='alunos.aluno')),
                ('disciplina', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='ciclos_estudo', to='disciplinas.disciplina')),
            ],
            options={
                'verbose_name': 'Ciclo de Estudo',
                'verbose_name_plural': 'Ciclos de Estudo',
            },
        ),
    ]
