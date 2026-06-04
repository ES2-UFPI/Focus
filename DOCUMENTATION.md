# Focus — Project Documentation

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Getting Started](#getting-started)
4. [Backend](#backend)
   - [Tech Stack](#backend-tech-stack)
   - [Project Structure](#backend-project-structure)
   - [Data Models](#data-models)
   - [API Reference](#api-reference)
   - [Authentication](#authentication)
5. [Frontend](#frontend)
   - [Tech Stack](#frontend-tech-stack)
   - [Project Structure](#frontend-project-structure)
   - [State Management](#state-management)
   - [UI Components](#ui-components)
6. [Development Workflow](#development-workflow)
7. [Contributing](#contributing)

---

## Overview

**Focus** is a student productivity platform that helps learners organize their academic life. It combines study cycle planning, material management, activity tracking, and consistency monitoring in a single application.

### Core Features

| Feature | Description | Status |
|---------|-------------|--------|
| Biblioteca de Materiais | Organizar PDFs, links, resumos e vídeos por disciplina | ✅ Implemented |
| Ciclo de Estudos | Planejar sessões de estudo semanais por disciplina | 🔄 In Progress |
| Atividades Acadêmicas | Gerenciar provas, trabalhos e seminários | ✅ Implemented |
| Metas Semanais | Definir e acompanhar metas de estudo | ✅ Implemented |
| Consistência Semanal | Visualizar índice de regularidade e horas estudadas | 🔄 In Progress |
| Relatórios | Análise de desempenho e distribuição por disciplina | 📋 Planned |

---

## Architecture

Focus adopts a client–server architecture with a REST API backend and a cross-platform mobile/desktop frontend.

```
┌──────────────────────────────────────────────────────┐
│                    Flutter Client                     │
│  (iOS · Android · Web · macOS · Windows · Linux)     │
│                                                       │
│  Provider (state) → ApiService (HTTP) → REST API     │
└───────────────────────┬──────────────────────────────┘
                        │ HTTPS / Token Auth
┌───────────────────────▼──────────────────────────────┐
│               Django REST Framework                   │
│                                                       │
│   ViewSets → Serializers → Models → SQLite/Postgres   │
└──────────────────────────────────────────────────────┘
```

### Design Principles

- **Ownership isolation** — every resource is scoped to the authenticated `Aluno`; cross-user access is rejected at the ViewSet layer.
- **Single responsibility** — each Django app owns one domain entity and exposes its own serializer and ViewSet.
- **UI consistency** — the Flutter frontend uses `shadcn_ui` to maintain a coherent design language across all screens.

---

## Getting Started

### Prerequisites

| Tool | Minimum Version |
|------|----------------|
| Python | 3.11+ |
| Django | 5.1+ |
| Flutter SDK | 3.41.0+ |
| Dart SDK | 3.11.5+ |

### Backend

```bash
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser   # create a test Aluno
python manage.py runserver
```

API available at `http://localhost:8000/api/`

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

> **Android emulator note:** the API base URL is set to `http://10.0.2.2:8000` which maps to `localhost` on the host machine from inside the Android emulator. Adjust `lib/services/api_service.dart` for physical devices or web.

---

## Backend

### Backend Tech Stack

| Library | Version | Purpose |
|---------|---------|---------|
| Django | 5.1.6 | Web framework |
| Django REST Framework | 3.17.1 | REST API |
| rest_framework.authtoken | bundled | Token-based authentication |
| django-cors-headers | 4.9.0 | CORS for Flutter client |
| SQLite | bundled | Development database |

### Backend Project Structure

```
backend/
├── focus_api/                 # Django project settings
│   ├── settings.py
│   └── urls.py
├── alunos/                    # User entity (AbstractUser)
├── disciplinas/               # Academic subject entity
├── tarefas_disciplina/        # Subject-specific tasks
├── avaliacoes_academicas/     # Academic assessments (provas, trabalhos)
├── metas_semanais/            # Weekly study goals
├── ciclos_estudo/             # Study cycle sessions
└── materiais_estudo/          # Study material library ← main feature
```

Each app follows the standard Django app layout:

```
<app>/
├── migrations/
│   └── 0001_initial.py
├── models.py          # Domain entity
├── serializers.py     # DRF serializer (explicit field list)
├── views.py           # ModelViewSet with ownership filtering
├── admin.py
└── tests.py
```

### Data Models

#### Aluno (alunos)
Extends `django.contrib.auth.models.AbstractUser`. Used as `AUTH_USER_MODEL`.

| Field | Type | Notes |
|-------|------|-------|
| id | UUIDField | Primary key |
| nome | CharField(255) | Display name |
| email | EmailField | Unique, used as `USERNAME_FIELD` |
| data_cadastro | DateTimeField | Auto set on creation |

#### Disciplina (disciplinas)

| Field | Type | Notes |
|-------|------|-------|
| id | UUIDField | Primary key |
| aluno | FK → Aluno | Owner |
| nome | CharField(255) | |
| codigo | CharField(50) | Unique per aluno |
| cor | CharField(20) | Hex color for UI |
| carga_horaria_oficial | IntegerField | |
| ativo | BooleanField | |

#### MaterialEstudo (materiais_estudo)

| Field | Type | Notes |
|-------|------|-------|
| id | UUIDField | Primary key |
| aluno | FK → Aluno | Owner (set automatically on create) |
| disciplina | FK → Disciplina | |
| titulo | CharField(255) | |
| tipo | CharField | `PDF`, `Resumo`, `Link`, `Video`, `Outro` |
| url | CharField(500) | Optional |
| arquivo_path | CharField(500) | Optional |
| descricao | TextField | Optional |
| data_insercao | DateTimeField | Auto set on creation |

#### AtividadeAcademica (avaliacoes_academicas)

| Field | Type | Notes |
|-------|------|-------|
| id | UUIDField | Primary key |
| aluno | FK → Aluno | |
| disciplina | FK → Disciplina | |
| tipo | CharField | `Prova`, `Trabalho`, `Seminario`, `Outro` |
| data | DateField | |
| nota | DecimalField(5,2) | Optional |
| peso | DecimalField(5,2) | Optional |
| observacao | TextField | Optional |

#### MetaSemanal (metas_semanais) · CicloEstudo (ciclos_estudo) · TarefaDisciplina (tarefas_disciplina)
See respective `models.py` files.

### API Reference

Base URL: `/api/`

#### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/token/` | Obtain auth token (`{"username": "<email>", "password": "<senha>"}`) |

All other endpoints require `Authorization: Token <token>` header.

#### Materials — `/api/materiais-estudo/`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/materiais-estudo/` | List materials (owner-scoped) |
| POST | `/api/materiais-estudo/` | Create material |
| GET | `/api/materiais-estudo/{id}/` | Retrieve material |
| PATCH | `/api/materiais-estudo/{id}/` | Update material |
| DELETE | `/api/materiais-estudo/{id}/` | Delete material |

**Query parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `disciplina` | UUID | Filter by disciplina ID |
| `tipo` | string | Filter by type (`PDF`, `Link`, etc.) |
| `search` | string | Full-text search on `titulo` and `descricao` |
| `ordering` | string | `data_insercao`, `titulo`, prefix `-` for descending |

#### Other Resources

| Resource | Endpoint |
|----------|----------|
| Alunos | `/api/alunos/` |
| Disciplinas | `/api/disciplinas/` |
| Tarefas Disciplina | `/api/tarefas-disciplina/` |
| Atividades Acadêmicas | `/api/avaliacoes-academicas/` |
| Metas Semanais | `/api/metas-semanais/` |
| Ciclos de Estudo | `/api/ciclos-estudo/` |

### Authentication

Focus uses **DRF Token Authentication**. Obtain a token via `POST /api/auth/token/`, then pass it on every subsequent request:

```http
Authorization: Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b
```

Tokens are per-user and do not expire by default. Implement token rotation in production.

---

## Frontend

### Frontend Tech Stack

| Library | Version | Purpose |
|---------|---------|---------|
| Flutter | 3.41.0+ | Cross-platform UI framework |
| shadcn_ui | 0.54.0 | Design system (shadcn/ui port) |
| provider | 6.1.5 | State management |
| http | 1.6.0 | HTTP client |
| flutter_secure_storage | 9.2.4 | Secure token storage |
| intl | 0.20.2 | Date/number formatting |

### Frontend Project Structure

```
frontend/lib/
├── main.dart                      # App entry point — ShadApp + MultiProvider + AppShell
├── models/
│   ├── disciplina.dart            # Disciplina data class + fromJson
│   └── material_estudo.dart       # MaterialEstudo data class + fromJson/toJson
├── services/
│   └── api_service.dart           # HTTP layer — all API calls
├── providers/
│   └── materiais_provider.dart    # ChangeNotifier — state + filtering logic
├── pages/
│   └── biblioteca_materiais_page.dart  # Main Biblioteca de Materiais screen
└── widgets/
    ├── app_sidebar.dart            # Side navigation (dark, violet accent)
    ├── material_form_dialog.dart   # Add / Edit material form (ShadDialog)
    └── delete_confirm_dialog.dart  # Delete confirmation (ShadDialog.alert)
```

### State Management

`MateriaisProvider` (ChangeNotifier) manages:
- List of materials from the API
- List of disciplines for filters and the form
- Active filters: `selectedDisciplinaId`, `selectedTipo`, `searchQuery`
- Loading and error states

Widgets call `context.read<MateriaisProvider>()` to dispatch actions (add, update, delete, set filters) and `context.watch<MateriaisProvider>()` to rebuild on state changes.

### UI Components

The app uses `ShadApp` as its root widget with `ShadVioletColorScheme` to match the Focus branding.

Key components used in Biblioteca de Materiais:

| Component | Usage |
|-----------|-------|
| `ShadCard` | Table container |
| `ShadTable.list` | Materials table |
| `ShadButton` / `ShadButton.outline` / `ShadButton.ghost` | All action buttons |
| `ShadInput` | Search field |
| `ShadSelect` | Tipo and Disciplina dropdowns in the form |
| `ShadInputFormField` | Validated form fields |
| `ShadForm` | Form wrapper with validation |
| `ShadDialog` | Add/Edit form dialog |
| `ShadDialog.alert` | Delete confirmation |
| `ShadBadge.secondary` | Tipo badge in the table |
| `ShadPopover` | Row actions menu (edit / delete) |
| `ShadToaster` / `ShadToast` | Feedback notifications |
| `LucideIcons` | Icon set (included with shadcn_ui) |

---

## Development Workflow

### Branching Strategy

```
master          ← production-ready (protected)
dev             ← integration branch — all PRs merge here
feat/<name>     ← feature branches (from dev)
fix/<name>      ← bug fix branches (from dev)
Samuel#<issue>  ← issue branches following project convention
```

### Pull Request Process

1. Branch from `dev`
2. One commit per logical unit of work
3. Open PR targeting `dev`
4. At least one reviewer approval required
5. Resolve all conflicts before merging (rebase on top of dev)
6. Squash merge preferred for cleaner history

### Conflict Resolution

When multiple PRs add entries to `settings.py` (INSTALLED_APPS) or `urls.py` (router), rebase conflicts arise. The rule is: **always keep all existing entries and append the new one**. See git history for examples.

---

## Contributing

1. Pick an open issue from the project backlog
2. Comment on the issue to signal you are working on it
3. Create a branch following the naming convention above
4. Implement the feature or fix
5. Ensure `python manage.py check` passes (backend) and `flutter analyze` passes (frontend)
6. Open a PR with a clear description referencing the issue number (`closes #<n>`)
7. Address review comments and push additional commits (do not force-push after review starts)
