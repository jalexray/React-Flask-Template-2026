## Dumbo v0.1 Plan — Waitlist (MySQL + SQLAlchemy)

### Goal
Implement the **waitlist MVP** described in `docs/v0.1/v01-scope.md`, using:
- **MySQL** for persistence
- **SQLAlchemy** to define tables/models and query data
- Existing repo architecture: **React (Vite)** frontend calling **Flask** JSON endpoints under `/api/*`

### Constraints / assumptions
- Keep the backend simple (single Flask app in `api/api.py` initially).
- Use **environment variables** for database credentials; no secrets committed.
- Prefer minimal dependencies and minimal operational complexity for v0.1.

---

## Architecture decisions (v0.1)

### MySQL: local + production
- **Local dev**: run MySQL via Docker Compose (recommended) OR use an existing local MySQL instance.
- **Production**: managed MySQL (e.g., RDS, PlanetScale, DigitalOcean, etc.).

### SQLAlchemy + migrations
- Use **SQLAlchemy ORM** for model definitions.
- Use **Alembic** for schema migrations.

### Data model
Primary table: `waitlist_signups`
- Unique on normalized `email` (lowercased + trimmed)
- Keep timestamps (`created_at`, `updated_at`)
- Store UTM fields + optional source URL
- For privacy: store **hashed** IP (optional), not raw IP

---

## Implementation plan (backend)

### 1) Add backend dependencies
Add Python deps in the backend environment (whatever the repo uses in `api/venv/`):
- `Flask`
- `SQLAlchemy`
- MySQL driver: `pymysql`
- `Flask-SQLAlchemy` (optional convenience) OR plain SQLAlchemy session management
- `alembic`

Output:
- Document the exact install steps in `README.md` (later)

### 2) Database configuration + connection
Add config in Flask:
- `DATABASE_URL` (preferred single var), e.g.
  - `mysql+pymysql://user:pass@localhost:3306/dumbo?charset=utf8mb4`
- Or separate vars: `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`

Also:
- Ensure engine uses `utf8mb4` (emoji-safe, modern default)
- Provide sensible connection pool defaults

### 3) Set up Alembic migrations
Create Alembic scaffolding and wire it to `DATABASE_URL`:
- Initialize Alembic in `api/` (so backend tooling lives with backend)
- Configure `alembic/env.py` to read `DATABASE_URL` from the environment at runtime
- Point Alembic’s `target_metadata` at your SQLAlchemy `Base.metadata` so `--autogenerate` works

Commands (example flow):
- `alembic init alembic`
- `alembic revision --autogenerate -m "create waitlist_signups"`
- `alembic upgrade head`

### 3) Define SQLAlchemy model(s)
Create a `WaitlistSignup` model with fields from scope:
- `id` (auto-increment int or UUID; pick one and standardize)
- `email` (unique, indexed)
- `full_name`, `company`, `role`, `team_size`, `primary_goal`, `where_you_heard`
- `source_url`
- `utm_source`, `utm_medium`, `utm_campaign`, `utm_term`, `utm_content`
- `ip_hash` (nullable)
- `created_at`, `updated_at`

Normalization rules:
- `email_normalized = email.strip().lower()`
- Store normalized email in `email` (or store both `email` + `email_normalized`; simplest is store normalized).

### 4) Implement API endpoints
#### `POST /api/waitlist`
Accept JSON payload:
- Required: `email`
- Optional: other fields + UTMs + `source_url`
- Honeypot field: e.g. `company_website` (must be empty)

Behavior:
- Validate email (basic format check)
- If honeypot filled: return `400` or `200` with `{status:"ok"}` (choose approach; simplest is `400`)
- Upsert by normalized email:
  - If new: create row → return `{status:"created"}`
  - If exists: optionally update missing optional fields → return `{status:"existing"}`

Errors:
- Return structured JSON errors (e.g. `{error: {code, message}}`)

### 5) Rate limiting + basic spam defense
Minimum:
- Honeypot on frontend + backend check

Recommended:
- Per-IP rate limit (e.g., `flask-limiter`) on `POST /api/waitlist` (e.g. 5/min)

## Implementation plan (frontend)

### 6) Landing page UI
Replace starter counter UI with a landing page containing:
- Hero + CTA
- “Who it’s for” + “What you get”
- Static example output section
- Waitlist form (primary CTA)

### 7) Waitlist form behavior
Implement:
- Controlled inputs
- Inline validation for email
- Submit to `POST /api/waitlist`
- Loading + success state
- Existing-email messaging (“You’re already on the list”)
- Error state with retry

UTM + source capture:
- On load, parse `window.location.search` UTMs
- Include `source_url: window.location.href` in payload

---

## Local development plan (MySQL)

### 9) Add Docker Compose (recommended)
Add `docker-compose.yml` with a `mysql:8` service:
- `MYSQL_DATABASE=dumbo`
- `MYSQL_USER=dumbo`
- `MYSQL_PASSWORD=...`
- `MYSQL_ROOT_PASSWORD=...`
- Port mapping `3306:3306`
- Volume for persistence (so signups survive restarts)

Then backend points to it via `DATABASE_URL`.

If you prefer not to add Docker:
- Document manual MySQL setup steps instead.

---

## Testing & verification

### 10) Manual test checklist
- Submit valid email → `created`
- Submit same email again → `existing`
- Honeypot filled → rejected
- Bad email → validation error

### 11) Lightweight automated tests (optional for v0.1)
- Flask test client tests for `/api/waitlist`
- Model constraint test for unique email

---

## Rollout / deployment notes (v0.1)
- Set `DATABASE_URL` in hosting provider secrets.
- Confirm CORS/proxy setup:
  - Dev uses Vite proxy (`/api/*` → Flask).
  - Production approach TBD (separate deploy vs single deploy).

---

## Milestones
- **M1**: MySQL running locally + SQLAlchemy model created + migration applied
- **M2**: `POST /api/waitlist` live (upsert + validation + honeypot)
- **M3**: Landing page + waitlist form wired up end-to-end
- **M4**: Basic rate limit + spam hardening
- **M5**: Polish (copy, accessibility, small analytics/logging)
