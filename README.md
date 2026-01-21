## React + Flask Starter (Vite + Flask App Factory)

Starter repo for building a product with:

- **Frontend**: React + Vite
- **Backend**: Flask **application factory** + blueprints, SQLAlchemy, Alembic migrations

The key convention is **all API routes live under `/api`**, so:

- In development, Vite can proxy `/api/*` to Flask (no CORS hassle)
- In production, the Flask app can serve the built React SPA and the API from **one origin**

## How it fits together

### Dev mode (two servers)

- **Vite dev server** runs the frontend at `http://localhost:5173`
- **Flask** runs the API at `http://localhost:5009`
- The browser calls `fetch('/api/...')` from the Vite origin
- Vite proxies `/api/*` → Flask (configured in `vite.config.js`)

### Production mode (one server)

- The React app is built to static assets (`npm run build` → `dist/`)
- Flask serves those built assets from `/` (SPA) and exposes JSON under `/api`
- **Gunicorn** runs the Flask app on port **3000**

## Project layout

```text
.
├── api/
│   ├── __init__.py           # Flask app factory `create_app()`
│   ├── api_bp.py             # Parent `/api` blueprint + feature blueprint registration
│   ├── config.py             # Loads `api/.env` and builds configuration
│   ├── main/                 # Example API blueprint
│   │   ├── __init__.py
│   │   └── routes.py         # Example routes: /api/time, /api/date
│   ├── models.py             # Example SQLAlchemy model(s)
│   └── requirements.txt      # Backend dependencies
├── application.py            # WSGI entrypoint exposing `app` (Gunicorn imports this)
├── migrations/               # Alembic / Flask-Migrate migrations (created by `flask db init`)
├── src/                      # React app source
├── vite.config.js            # Dev proxy `/api` → Flask
├── Dockerfile.combo          # Multi-stage build: React build + Python/Gunicorn runtime
├── setup-env.sh              # Helper to create `api/.env`
├── db-setup.sh               # Helper to create a local MySQL db + append creds to `api/.env`
└── fly.mysql.toml            # Example Fly.io config for running MySQL as a separate Fly app
```

## Local development

### Prerequisites

- **Node.js** (for Vite/React)
- **Python 3.12+** (recommended; Docker uses 3.12)

### Install frontend dependencies

```bash
npm install
```

### Create the backend virtualenv + install backend deps

`npm run api` expects a venv at `api/venv/`.

```bash
python3 -m venv api/venv
api/venv/bin/pip install -r api/requirements.txt
```

### Configure environment variables

The backend loads environment variables from `api/.env` (via `python-dotenv`).

- **Option 0 (copy an example)**:

```bash
cp api/env.example api/.env
```

- **Option A (helper script)**:

```bash
chmod +x setup-env.sh
./setup-env.sh
```

- **Option B (manual)**: create `api/.env`:

```bash
OPENAI_KEY=your_key_optional
FLASK_ENV=development
FLASK_DEBUG=1
FLASK_RUN_PORT=5009
```

Notes:

- **Database is optional** to start. If no DB env vars are set, the app defaults to a local SQLite file at `api/app.db`.

### Run the backend (Flask API)

In one terminal:

```bash
npm run api
```

Flask listens on **`http://localhost:5009`**.

### Run the frontend (Vite + React)

In another terminal:

```bash
npm run dev
```

Open **`http://localhost:5173`**.

## API: how it works

### Application factory (`create_app`)

The backend is created by `api.create_app()` and exposed for production by `application.py` (Gunicorn imports `application:app`).

- **Static hosting in production**: the Flask app is configured with `static_folder='../build'` and serves `index.html` at `/` so your built React app is reachable at the site root.
- **API prefix**: a parent blueprint (`api/api_bp.py`) is mounted at `/api`, and feature blueprints register under it.

### Adding endpoints

- Add a new blueprint folder under `api/` (similar to `api/main/`)
- Register it in `api/api_bp.py`
- Keep routes relative to the parent prefix so they stay under `/api`

### Example endpoints

- **`GET /api/time`** → `{ "time": 173... }`
- **`GET /api/date`** → `{ "date": "YYYY-MM-DD" }`

## Database + migrations

### Configuration

`api/config.py` supports:

- **`DATABASE_URL`** (recommended for deployment)
- Or **`DATABASE_NAME` / `DATABASE_USER` / `DATABASE_PASSWORD`** plus optional:
  - `DATABASE_HOST` (default: `localhost`)
  - `DATABASE_PORT` (default: `3306`)
- If nothing is set, it falls back to **SQLite** at `api/app.db`.

### Local MySQL helper (optional)

If you want local MySQL, `db-setup.sh` can:

- Create a DB + user
- Append `DATABASE_NAME`, `DATABASE_USER`, `DATABASE_PASSWORD` to `api/.env`

```bash
chmod +x db-setup.sh
./db-setup.sh
```

### Running migrations (Flask-Migrate / Alembic)

Once you initialize migrations (`flask db init`), typical workflow is:

```bash
api/venv/bin/flask --app api:create_app db migrate -m "describe your change"
api/venv/bin/flask --app api:create_app db upgrade
```

## Docker (combined frontend + backend)

This template includes a combined Docker build in `Dockerfile.combo`:

- **Stage 1 (Node)**: installs npm deps and builds the React app (`npm run build`)
- **Stage 2 (Python)**:
  - copies the built frontend into `/app/build`
  - installs `api/requirements.txt`
  - runs Flask via **Gunicorn** on port **3000**

### Build

```bash
docker build --no-cache -f Dockerfile.combo -t react-flask-app .
```

### Run

```bash
docker run --rm -p 3000:3000 react-flask-app
```

Then open `http://localhost:3000`:

- `/` serves the React app
- `/api/time` hits Flask

### Passing environment variables to Docker

Example:

```bash
docker run --rm -p 3000:3000 \
  -e DATABASE_URL="mysql+mysqlconnector://user:pass@host:3306/db?auth_plugin=mysql_native_password" \
  -e OPENAI_KEY="..." \
  react-flask-app
```

## Deploying on Fly.io

This repo is designed to deploy as **one container** (React build + Flask/Gunicorn) listening on **port 3000**.

### Prerequisites

- Install and login with Fly CLI (`flyctl`) (see [Fly.io docs](https://fly.io/docs/flyctl/))
- Decide whether you’ll use:
  - **No external DB** (SQLite; not recommended for production durability)
  - **Fly MySQL** (example config included)

### Deploy the app (container)

From the repo root:

```bash
fly launch --no-deploy --dockerfile Dockerfile.combo
```

When Fly asks about ports/config, make sure your `fly.toml` uses:

- **internal port**: `3000`

Then set secrets (at minimum, your DB settings if you’re using MySQL):

```bash
fly secrets set \
  DATABASE_URL="mysql+mysqlconnector://user:pass@your-mysql.internal:3306/db?auth_plugin=mysql_native_password"
```

Deploy:

```bash
fly deploy --dockerfile Dockerfile.combo
```

### Fly MySQL (optional)

If you want a MySQL instance on Fly, this repo includes `fly.mysql.toml` as a starting point.

High level:

- Create a separate Fly app for MySQL (with a volume)
- Deploy MySQL using `fly.mysql.toml`
- Point your Flask app at it via `DATABASE_URL` (recommended)

Example flow (edit names/region/credentials to your needs):

```bash
# 1) Create the MySQL app (no deploy yet)
fly launch --no-deploy --image mysql:8.0.37

# 2) Create a persistent volume for MySQL data
fly volumes create mysqldata --size 10 -a <mysql-app-name>

# 3) Set MySQL secrets (passwords)
fly secrets set MYSQL_PASSWORD="<app-user-password>" MYSQL_ROOT_PASSWORD="<root-password>" -a <mysql-app-name>

# 4) Deploy MySQL using the provided config
fly deploy -a <mysql-app-name> -c fly.mysql.toml
```

Then point your Flask app at the internal hostname:

```bash
fly secrets set \
  DATABASE_URL="mysql+mysqlconnector://<user>:<pass>@<mysql-app-name>.internal:3306/<db>?auth_plugin=mysql_native_password"
```

The `fly.mysql.toml` file includes commented commands and a `flyctl proxy` example for local access.

## Troubleshooting

### API requests fail in dev

- Confirm Flask is running on `:5009` (`npm run api`)
- Confirm Vite proxy is set in `vite.config.js` (`/api` → `http://localhost:5009`)

### “ModuleNotFoundError” when running `npm run api`

- Make sure you created the venv at `api/venv/` and installed `api/requirements.txt`.