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
            name='AvaliacaoAcademica',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('tipo', models.CharField(choices=[('Prova', 'Prova'), ('Trabalho', 'Trabalho'), ('Seminario', 'Seminário'), ('Outro', 'Outro')], max_length=20)),
                ('data', models.DateField()),
                ('nota', models.DecimalField(blank=True, decimal_places=2, max_digits=5, null=True)),
                ('peso', models.DecimalField(blank=True, decimal_places=2, max_digits=5, null=True)),
                ('observacao', models.TextField(blank=True, null=True)),
                ('aluno', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='avaliacoes_academicas', to='alunos.aluno')),
                ('disciplina', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='avaliacoes_academicas', to='disciplinas.disciplina')),
            ],
            options={
                'verbose_name': 'Avaliação Acadêmica',
                'verbose_name_plural': 'Avaliações Acadêmicas',
            },
        ),
    ]
