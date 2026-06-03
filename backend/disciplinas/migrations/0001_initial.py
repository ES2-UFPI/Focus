import uuid
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Disciplina',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('nome', models.CharField(max_length=255)),
                ('codigo', models.CharField(max_length=50, unique=True)),
                ('descricao', models.TextField(blank=True, null=True)),
                ('cor', models.CharField(max_length=20)),
                ('carga_horaria_oficial', models.IntegerField()),
                ('ativo', models.BooleanField(default=True)),
            ],
            options={
                'verbose_name': 'Disciplina',
                'verbose_name_plural': 'Disciplinas',
            },
        ),
    ]
