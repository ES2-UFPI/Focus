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
            name='TarefaDisciplina',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('titulo', models.CharField(max_length=255)),
                ('descricao', models.TextField(blank=True, null=True)),
                ('prazo', models.DateTimeField()),
                ('concluida', models.BooleanField(default=False)),
                ('data_conclusao', models.DateTimeField(blank=True, null=True)),
                ('prioridade', models.CharField(choices=[('Baixa', 'Baixa'), ('Media', 'Média'), ('Alta', 'Alta')], default='Media', max_length=10)),
                ('aluno', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='tarefas_disciplina', to='alunos.aluno')),
                ('disciplina', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='tarefas_disciplina', to='disciplinas.disciplina')),
            ],
            options={
                'verbose_name': 'Tarefa de Disciplina',
                'verbose_name_plural': 'Tarefas de Disciplina',
            },
        ),
    ]
