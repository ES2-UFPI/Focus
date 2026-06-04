# Frontend

Aplicativo Flutter do projeto Focus.

## Pré-requisitos

- Flutter SDK instalado.
- Dart compatível com o SDK definido em `pubspec.yaml`.
- Backend Django iniciado, caso a aplicação passe a consumir a API local.

Verifique o ambiente Flutter:

```powershell
flutter doctor
```

## Instalação

Na pasta `frontend/`, baixe as dependências:

```powershell
flutter pub get
```

## Execução

Para listar os dispositivos disponíveis:

```powershell
flutter devices
```

Para executar no dispositivo selecionado:

```powershell
flutter run
```

Para executar no navegador Chrome:

```powershell
flutter run -d chrome
```

## Relação com o backend

O backend do projeto fica na pasta `../backend` e, em ambiente local, normalmente é iniciado em:

```text
http://127.0.0.1:8000/
```

A API REST fica em:

```text
http://127.0.0.1:8000/api/
```

Consulte o `readme.md` da raiz do projeto para o passo a passo completo de inicialização.
