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

Configure Flutter Web's non-secret API URL with:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

`backend/.env.example` contains local-only values for the Compose stack. Do
not use those values in a deployment. Production must supply a unique database
URL and session secret, HTTPS, explicit CORS origins, secure cookies, and
working SMTP credentials. Recovery requests must not be reported as delivered
when SMTP is unavailable.
