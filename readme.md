# Focus

Projeto com backend em Django REST Framework e frontend em Flutter.

## Estrutura

- `backend/`: API Django, banco SQLite local e apps de alunos, disciplinas, tarefas, eventos, materiais, sessoes de estudo e feedbacks.
- `frontend/`: aplicativo Flutter com suporte a Web, Windows, Android, iOS, Linux e macOS.

## Requisitos

- Python 3 instalado.
- Flutter SDK instalado.
- Google Chrome, Edge ou outro dispositivo Flutter disponivel para executar o frontend.

Validado neste ambiente com:

- Python 3.14.3.
- Flutter 3.41.9.
- Dart 3.11.5.

## Como iniciar o backend

Abra um terminal na raiz do projeto e execute:

```powershell
cd backend
py -3.11 -m venv venv
.\venv\Scripts\activate
python -m pip install --upgrade pip setuptools wheel
python -m pip install Django==5.1.6 djangorestframework==3.17.1 django-cors-headers==4.9.0
python manage.py migrate

python manage.py runserver 127.0.0.1:8000
```

A API fica disponivel em:

- `http://127.0.0.1:8000/api/`
- `http://127.0.0.1:8000/api/agenda/`
- `http://127.0.0.1:8000/admin/`

Observacao: o arquivo `backend/requirements.txt` existe, mas contem muitas bibliotecas que nao sao necessarias para iniciar esta API. Para uma instalacao minima e validada, use o comando `pip install` acima. Se preferir instalar tudo do arquivo, substitua o comando de instalacao por:

```powershell
python -m pip install -r requirements.txt
```

## Como iniciar o frontend

Em outro terminal, a partir da raiz do projeto, execute:

```powershell
cd frontend
flutter pub get
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 5173
```

O app Web fica disponivel em:

```text
http://127.0.0.1:5173
```

O frontend esta configurado para chamar o backend em:

```text
http://localhost:8000
```

Por isso, mantenha o backend rodando antes de abrir o frontend. Para executar em emulador Android, pode ser necessario trocar a URL base do app para `http://10.0.2.2:8000`, pois esse endereco aponta para o `localhost` da maquina host no emulador.

## Ordem recomendada

1. Inicie o backend.
2. Aplique as migracoes com `python manage.py migrate`.
3. Mantenha `python manage.py runserver 127.0.0.1:8000` rodando.
4. Em outro terminal, inicie o frontend com `flutter run -d chrome --web-hostname 127.0.0.1 --web-port 5173`.
5. Acesse `http://127.0.0.1:5173`.

## Comandos de verificacao

Com o backend rodando:

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8000/api/
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:8000/api/agenda/
```

Com o frontend rodando:

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:5173
```

Tambem foram validados:

```powershell
cd frontend
flutter analyze
flutter build web
```

## Resultado dos testes locais

- `python manage.py check`: passou sem erros.
- `python manage.py migrate`: aplicou todas as migracoes em `backend/db.sqlite3`.
- `GET /api/`: respondeu HTTP 200.
- `GET /api/agenda/`: respondeu HTTP 200 com `{"itens":[],"recomendacoes":[]}`.
- `flutter pub get`: concluiu.
- `flutter analyze`: passou sem erros.
- `flutter build web`: concluiu e gerou `frontend/build/web`.
- `flutter run -d chrome --web-hostname 127.0.0.1 --web-port 5173`: iniciou o frontend; `GET /` em `127.0.0.1:5173` respondeu HTTP 200.

