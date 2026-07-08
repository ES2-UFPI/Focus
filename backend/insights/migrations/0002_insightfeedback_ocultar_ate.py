from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('insights', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='insightfeedback',
            name='ocultar_ate',
            field=models.DateTimeField(
                blank=True,
                null=True,
                help_text='Enquanto no futuro, oculta o insight deste aluno (punição de 7 dias por feedback negativo).',
            ),
        ),
    ]
