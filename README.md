# MindBoop API

Rails 8 API backend for the MindBoop Tauri app.

## Setup

```bash
mise install
bundle install
bin/rails db:prepare
bin/rails server        # http://localhost:3000
bin/rails test
```

## Authentication

JWT bearer auth under `/api/v1/auth`. See [docs/authentication.md](docs/authentication.md) for endpoints, token details and how to protect controllers.
