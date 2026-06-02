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
            name='MetaSemanal',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('horas_planejadas', models.DecimalField(decimal_places=2, max_digits=5)),
                ('data_inicio', models.DateField()),
                ('data_fim', models.DateField()),
                ('ativa', models.BooleanField(default=True)),
                ('aluno', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='metas_semanais', to='alunos.aluno')),
                ('disciplina', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='metas_semanais', to='disciplinas.disciplina')),
            ],
            options={
                'verbose_name': 'Meta Semanal',
                'verbose_name_plural': 'Metas Semanais',
            },
        ),
    ]
