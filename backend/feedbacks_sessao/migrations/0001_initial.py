import django.db.models.deletion
import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('sessoes_estudo', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='FeedbackSessao',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('nota_foco', models.IntegerField()),
                ('nivel_dificuldade', models.CharField(choices=[('Baixa', 'Baixa'), ('Media', 'Media'), ('Alta', 'Alta')], default='Media', max_length=10)),
                ('comentario', models.TextField(blank=True, null=True)),
                ('data_feedback', models.DateTimeField(auto_now_add=True)),
                ('aluno', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='feedbacks_sessao', to=settings.AUTH_USER_MODEL)),
                ('sessao_estudo', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='feedbacks_sessao', to='sessoes_estudo.sessaoestudo')),
            ],
            options={
                'verbose_name': 'Feedback de Sessao',
                'verbose_name_plural': 'Feedbacks de Sessao',
            },
        ),
    ]
