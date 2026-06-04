# Focus

Projeto com backend em Django REST Framework e frontend em Flutter.

## Estrutura

- `backend/`: API Django, banco SQLite local e rotas REST.
- `frontend/`: aplicativo Flutter.
- `class-diagram.jpeg`: diagrama de classes do projeto.

## Pré-requisitos

Instale antes de iniciar:

- Python 3.11 ou superior.
- Flutter SDK compatível com Dart `^3.11.5`.
- Git, caso vá clonar o repositório.

Verifique as instalações:

```powershell
python --version
flutter --version
```

## Iniciar o backend

Abra um terminal na raiz do projeto e entre na pasta do backend:

```powershell
cd backend
```

Crie e ative um ambiente virtual:

```powershell
py -3.11 -m venv venv
.\venv\Scripts\Activate.ps1
python -m pip install --upgrade pip setuptools wheel


Instale as dependências:
pip install -r requirements.txt

```

Crie ou atualize o banco local:

```powershell
python manage.py migrate
```

Inicie a API:

```powershell
python manage.py runserver
```

Por padrão, o backend fica disponível em:

```text
http://127.0.0.1:8000/
```

Rotas principais:

- Admin Django: `http://127.0.0.1:8000/admin/`
- API REST: `http://127.0.0.1:8000/api/`
- Alunos: `http://127.0.0.1:8000/api/alunos/`
- Disciplinas: `http://127.0.0.1:8000/api/disciplinas/`
- Tarefas: `http://127.0.0.1:8000/api/tarefas-disciplina/`
- Avaliações acadêmicas: `http://127.0.0.1:8000/api/avaliacoes-academicas/`
- Metas semanais: `http://127.0.0.1:8000/api/metas-semanais/`
- Ciclos de estudo: `http://127.0.0.1:8000/api/ciclos-estudo/`
- Materiais de estudo: `http://127.0.0.1:8000/api/materiais-estudo/`

Para criar um usuário administrador:

```powershell
python manage.py createsuperuser
```

## Regras de negocio das entidades

- **Aluno**: representa o usuario estudante do sistema, identificado por email unico. Centraliza o vinculo com disciplinas, tarefas, metas, sessoes, feedbacks e recompensas.
- **Disciplina**: representa uma materia vinculada a um aluno. Possui codigo unico, carga horaria oficial, cor de identificacao e status ativo/inativo.
- **TarefaDisciplina**: representa uma tarefa de uma disciplina para um aluno. Controla prazo, prioridade, conclusao e data de conclusao.
- **MaterialEstudo**: representa um material de apoio associado a aluno e disciplina. Pode ser PDF, resumo, link, video ou outro tipo, com URL ou caminho de arquivo opcional.
- **AvaliacaoAcademica**: representa uma avaliacao de uma disciplina para um aluno. Armazena tipo, data, nota, peso e observacoes academicas.
- **CicloEstudo**: representa um periodo planejado de estudo para uma disciplina. Define data de inicio, data de fim e se o ciclo esta ativo.
- **MetaSemanal**: representa a meta de horas planejadas para uma disciplina em uma semana. Controla periodo de validade e se a meta esta ativa.
- **SessaoEstudo**: representa uma sessao real de estudo de um aluno em uma disciplina. Controla inicio, fim, duracao, conclusao e observacoes.
- **FeedbackSessao**: representa o feedback de um aluno sobre uma sessao de estudo. Registra nota de foco, nivel de dificuldade, comentario e data automatica do feedback.
- **Recompensa**: representa uma recompensa vinculada a um aluno. Controla titulo, descricao, pontos necessarios, status de resgate e data de resgate.

## Iniciar o frontend

Abra outro terminal na raiz do projeto e entre na pasta do frontend:

```powershell
cd frontend
```

Baixe as dependências:

```powershell
flutter pub get
```

Liste os dispositivos disponíveis:

```powershell
flutter devices
```

Execute o aplicativo:

```powershell
flutter run
```

Para executar no navegador, use:

```powershell
flutter run -d chrome
```

## Fluxo recomendado de desenvolvimento

1. Inicie o backend com `python manage.py runserver`.
2. Em outro terminal, inicie o frontend com `flutter run`.
3. Acesse ou teste os endpoints em `http://127.0.0.1:8000/api/`.

## Observações

- O banco de dados local usa SQLite e é criado em `backend/db.sqlite3` após as migrações.
- Arquivos gerados, como `db.sqlite3`, `venv/`, `.dart_tool/` e `build/`, estão ignorados pelo Git.
- Caso o PowerShell bloqueie a ativação do ambiente virtual, execute o terminal como administrador ou ajuste a política de execução do usuário.
