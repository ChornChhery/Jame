# Jame API

The API keeps database access and credentials on the server. For local
development, start PostgreSQL, FastAPI, and Mailpit from the repository root:

```powershell
docker compose up -d --wait postgres mailpit api
```

The API listens at `http://localhost:8000`; its liveness endpoint is
`http://localhost:8000/health`, and its PostgreSQL readiness endpoint is
`http://localhost:8000/ready`. Mailpit's inbox is at
`http://localhost:8025` and its SMTP service is available to the API at
`mailpit:1025`.

The API container applies Alembic migrations before serving requests. Its
PostgreSQL data is isolated in the `jame-postgres-data` Compose volume.

Configure Flutter Web's non-secret API URL with:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

`backend/.env.example` contains local-only values for the Compose stack. Do
not use those values in a deployment. Production must provide `DATABASE_URL`,
a unique `SESSION_SECRET` (at least 32 characters), explicit
`ALLOWED_ORIGINS`, and SMTP settings (`SMTP_HOST`, `SMTP_PORT`,
`SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_USE_TLS=true`, and `SMTP_FROM`).
Set `ENVIRONMENT=production` and `COOKIE_SECURE=true`; serve the API over
HTTPS. The API rejects production configuration without SMTP credentials,
TLS, and secure cookies. Recovery requests must not be reported as delivered
when SMTP is unavailable.

For a physical device on a trusted development network, set
`JAME_API_BIND_ADDRESS=0.0.0.0` before starting Compose and use the host
machine's LAN address in Flutter's `API_BASE_URL`. Keep the default loopback
binding for local browser development and do not expose development secrets
or services to untrusted networks.
