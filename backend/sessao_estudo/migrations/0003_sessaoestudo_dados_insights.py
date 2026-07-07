from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('sessao_estudo', '0002_sessaoestudo_evento_academico'),
    ]

    operations = [
        migrations.AddField(
            model_name='sessaoestudo',
            name='energia_inicial',
            field=models.PositiveSmallIntegerField(
                blank=True,
                help_text='Energia/disposição informada antes da sessão (1 a 5).',
                null=True,
                validators=[MinValueValidator(1), MaxValueValidator(5)],
            ),
        ),
        migrations.AddField(
            model_name='sessaoestudo',
            name='interrupcoes',
            field=models.PositiveIntegerField(
                default=0,
                help_text='Quantidade de interrupções registradas durante a sessão.',
            ),
        ),
        migrations.AddField(
            model_name='sessaoestudo',
            name='tipo_atividade',
            field=models.CharField(
                blank=True,
                choices=[
                    ('LEITURA', 'Leitura'),
                    ('EXERCICIO', 'Exercício'),
                    ('REVISAO', 'Revisão'),
                ],
                help_text='Método principal usado na sessão.',
                max_length=10,
                null=True,
            ),
        ),
    ]
