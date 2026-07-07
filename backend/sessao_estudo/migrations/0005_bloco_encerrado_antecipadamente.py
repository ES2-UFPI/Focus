from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('sessao_estudo', '0004_blocopomodoro'),
    ]

    operations = [
        migrations.RemoveConstraint(
            model_name='blocopomodoro',
            name='bloco_incompleto_sem_produtividade',
        ),
        migrations.AlterField(
            model_name='blocopomodoro',
            name='status',
            field=models.CharField(
                choices=[
                    ('CONCLUIDO', 'Concluído'),
                    (
                        'ENCERRADO_ANTECIPADAMENTE',
                        'Encerrado antecipadamente',
                    ),
                    ('INCOMPLETO', 'Incompleto'),
                ],
                max_length=30,
            ),
        ),
        migrations.AddConstraint(
            model_name='blocopomodoro',
            constraint=models.CheckConstraint(
                condition=(
                    models.Q(
                        status__in=[
                            'CONCLUIDO',
                            'ENCERRADO_ANTECIPADAMENTE',
                        ]
                    ) |
                    models.Q(produtividade__isnull=True)
                ),
                name='bloco_incompleto_sem_produtividade',
            ),
        ),
    ]
