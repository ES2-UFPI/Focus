#!/usr/bin/env bash
set -o errexit

pip install -r requirements.txt

python manage.py collectstatic --no-input
python manage.py migrate

# Popula o perfil de demonstração apenas se a conta ainda estiver sem dados.
# Não derruba o deploy caso o seed falhe.
python manage.py seed_demo --if-empty || echo "seed_demo pulado/falhou (deploy segue)"
