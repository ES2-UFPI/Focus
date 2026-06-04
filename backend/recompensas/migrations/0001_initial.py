import django.db.models.deletion
import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Recompensa',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('titulo', models.CharField(max_length=255)),
                ('descricao', models.TextField(blank=True, null=True)),
                ('pontos_necessarios', models.IntegerField(default=0)),
                ('resgatada', models.BooleanField(default=False)),
                ('data_resgate', models.DateTimeField(blank=True, null=True)),
                ('aluno', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='recompensas', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Recompensa',
                'verbose_name_plural': 'Recompensas',
            },
        ),
    ]
