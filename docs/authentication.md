# Authentication

JWT bearer auth. Endpoints live under `/api/v1/auth` and take JSON bodies.

| Method | Path | Body | Returns |
| --- | --- | --- | --- |
| `POST` | `/signup` | `email`, `password` | token pair (`201`) or `422` with `details` |
| `POST` | `/login` | `email`, `password` | token pair, or `401 invalid_credentials` |
| `POST` | `/refresh` | `refresh_token` | new token pair; the old refresh token is revoked |
| `POST` | `/logout` | `refresh_token` | `204` |
| `GET` | `/me` | `Authorization: Bearer <access_token>` | `{ user }` |

A token pair looks like `{ access_token, token_type: "Bearer", expires_in, refresh_token, user: { id, email } }`.

- **Access tokens** are HS256 JWTs (`sub`, `exp`, `iat`, `iss`, `jti`) that expire after 15 minutes. They are signed with `credentials.jwt_secret` when set, otherwise with `secret_key_base`.
- **Refresh tokens** are random, opaque strings that last 30 days. Only their SHA-256 digest is stored. Each one is single-use: if a token that was already rotated gets presented again, the server revokes every refresh token that user holds.
- `signup`, `login` and `refresh` are rate-limited to 10 requests per 3 minutes per IP.

To protect a new controller, inherit from `ApplicationController`. The `Authentication` concern then requires a valid bearer token and sets `current_user`. Use `allow_unauthenticated_access` to opt out.
