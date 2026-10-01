# MindBoop API

Rails 8 API backend for the MindBoop Tauri app.

## Setup

Requires PostgreSQL (e.g. `brew install postgresql@18 && brew services start postgresql@18`). By default it connects over the local socket as your OS user. You can override that with `DATABASE_URL`, or with `DB_HOST`, `DB_PORT`, `DB_USERNAME` and `DB_PASSWORD`.

```bash
mise install
bundle install
bin/rails db:prepare
bin/rails server        # http://localhost:3000
bin/rails test
```

## Authentication

JWT bearer auth under `/api/v1/auth`. See [docs/authentication.md](docs/authentication.md) for endpoints, token details and how to protect controllers.
