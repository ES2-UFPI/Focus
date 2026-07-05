import uuid

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('sessao_estudo', '0003_sessaoestudo_dados_insights'),
    ]

    operations = [
        migrations.CreateModel(
            name='BlocoPomodoro',
            fields=[
                (
                    'id',
                    models.UUIDField(
                        default=uuid.uuid4,
                        editable=False,
                        primary_key=True,
                        serialize=False,
                    ),
                ),
                ('numero_ciclo', models.PositiveSmallIntegerField()),
                ('inicio', models.DateTimeField()),
                ('fim', models.DateTimeField()),
                ('duracao_planejada_segundos', models.PositiveIntegerField()),
                ('duracao_realizada_segundos', models.PositiveIntegerField()),
                (
                    'interrupcoes',
                    models.PositiveIntegerField(default=0),
                ),
                (
                    'status',
                    models.CharField(
                        choices=[
                            ('CONCLUIDO', 'Concluído'),
                            ('INCOMPLETO', 'Incompleto'),
                        ],
                        max_length=10,
                    ),
                ),
                (
                    'produtividade',
                    models.PositiveSmallIntegerField(
                        blank=True,
                        choices=[
                            (1, 'Muito baixa'),
                            (2, 'Baixa'),
                            (3, 'Regular'),
                            (4, 'Alta'),
                            (5, 'Muito alta'),
                        ],
                        help_text=(
                            'Avaliação opcional de produtividade do bloco '
                            '(1 a 5).'
                        ),
                        null=True,
                    ),
                ),
                ('data_criacao', models.DateTimeField(auto_now_add=True)),
                (
                    'sessao_estudo',
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name='blocos_pomodoro',
                        to='sessao_estudo.sessaoestudo',
                    ),
                ),
            ],
            options={
                'verbose_name': 'Bloco Pomodoro',
                'verbose_name_plural': 'Blocos Pomodoro',
                'ordering': ['-inicio'],
            },
        ),
        migrations.AddConstraint(
            model_name='blocopomodoro',
            constraint=models.CheckConstraint(
                condition=(
                    models.Q(status='CONCLUIDO') |
                    models.Q(produtividade__isnull=True)
                ),
                name='bloco_incompleto_sem_produtividade',
            ),
        ),
    ]
