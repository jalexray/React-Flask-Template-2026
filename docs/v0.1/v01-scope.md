## Dumbo v0.1 Scope — Waitlist MVP

### Context
Dumbo is an AI-native social listening platform that surfaces emerging narratives before they trend and tells modern marketing and comms teams what to say, where to say it, and why it will land.

Right now we need a **high-conversion waitlist** to capture demand, learn who’s interested, and qualify early users.

### Primary goal
Ship a public landing page + waitlist signup that:
- Captures **contact + qualification** data reliably
- Minimizes spam and duplicates
- Enables quick **export / outreach**
- Provides lightweight **analytics** on conversion

### Non-goals (v0.1)
- No full “Dumbo product” (no listening, dashboards, alerts, narrative detection)
- No authentication / user accounts
- No complex CRM automation (optional future)
- No multi-page marketing site (single-page is fine)

---

## Users & core journeys

### Personas
- **Comms lead / PR**: cares about narratives, reputation, response playbooks.
- **Brand / product marketing**: cares about positioning, audience language, channel strategy.
- **Social / community manager**: cares about realtime signals and what to post.
- **Agency strategist**: wants tooling to serve multiple clients.

### Journey A — Visitor joins waitlist (happy path)
1. Visitor lands on `/`
2. Reads value proposition + examples
3. Submits waitlist form
4. Sees confirmation (“You’re on the list”) and what happens next

### Journey B — Admin reviews/export leads
1. Admin exports waitlist list (CSV)
2. Uses list for outreach / interviews

---

## Product requirements (MVP)

### Landing page (frontend)
- **Single page** with clear sections:
  - **Hero**: “Catch narratives before they trend” + 1–2 sentence explanation
  - **Who it’s for**: marketing, comms, social
  - **What you get**: “what to say / where / why it works” (3–6 bullets)
  - **Example outputs** (static mock): sample narrative + recommended message + channel
  - **Waitlist form** (primary CTA) + repeated CTA near bottom
  - **Trust**: privacy note (“No spam. Unsubscribe anytime.”)
- **Responsive** (mobile-first), fast load, accessible labels and errors.

### Waitlist form fields
Minimum:
- **email** (required)
Recommended qualifiers (to segment + prioritize):
- **full_name** (optional)
- **company** (optional)
- **role** (optional; dropdown + “Other”)
- **team_size** (optional; ranges)
- **primary_goal** (optional; choose 1–3: brand monitoring, crisis detection, campaign insights, competitive, product launches, other)
- **where_you_heard** (optional; free text or dropdown)

Anti-spam:
- **honeypot** hidden field (must be empty)
- Basic rate limiting (per-IP) on submit (implementation detail below)

UX behavior:
- Inline validation (email format, required fields)
- Submit button disabled + loading state while posting
- Success state replaces form; optionally offer “Book a 15-min call” link (stub)
- If email already exists: show “You’re already on the waitlist” (not an error)

### Backend API (Flask)
We already use `/api/*` behind the Vite proxy. Add:
- `POST /api/waitlist`
  - Accepts JSON payload with fields above
  - Validates email + honeypot + basic payload shape
  - Upserts by normalized email (lowercase/trim)
  - Returns JSON `{ status: "created" | "existing" }`
- (Admin) `GET /api/waitlist/export`
  - Returns CSV download
  - Protected by a simple shared secret header (MVP) or disabled by default
  - Alternative: keep export as a local script instead of an API route (acceptable)

### Persistence (MVP)
Choose simplest reliable store:
- **SQLite** file in `api/` (local + small scale), with a single `waitlist_signups` table.

Schema (suggested):
- `id` (uuid or autoincrement)
- `email` (unique, indexed)
- `full_name`, `company`, `role`, `team_size`, `primary_goal`, `where_you_heard`
- `source_url` (page URL at submit time)
- `utm_source`, `utm_medium`, `utm_campaign`, `utm_term`, `utm_content` (optional)
- `ip_hash` (optional; store hash, not raw IP, for privacy)
- `created_at`, `updated_at`

---

## Analytics & measurement

### Event tracking (minimal)
Track:
- **Page view** (landing page)
- **Waitlist submit success**
- **Waitlist submit existing**
- **Waitlist submit error**

Implementation options (pick one later):
- Privacy-first (e.g., Plausible) OR basic server-side logging.

### Success metrics
- **Conversion rate**: submits / unique visits
- **Qualified lead mix**: roles, goals, team sizes
- **Spam rate**: rejected / total attempts

---

## Quality bar (MVP)
- **Reliability**: no lost signups; idempotent by email.
- **Security**: validate inputs; protect export; basic rate limit; no secrets in frontend.
- **Privacy**: collect only what we need; clear disclosure.
- **Accessibility**: labels, focus states, readable contrast, error messages tied to inputs.

---

## Edge cases to handle
- Duplicate email submissions (return `existing`)
- Invalid email format
- Bot/spam (honeypot filled, burst requests)
- Backend down: show friendly error and allow retry

---

## Out of scope / future iterations
- Double opt-in email + transactional confirmation email
- Integrations (HubSpot/Salesforce/Notion/Slack)
- Admin dashboard UI
- A/B tests, multi-variant landing pages
- “Book demo” scheduling integration (Calendly)

---

## Deliverables checklist (definition of done)
- Public landing page with waitlist form + confirmation UI
- `POST /api/waitlist` implemented and wired up from frontend
- Persistence layer (SQLite) with migration/creation on boot
- Export path (API or script) for CSV
- Minimal analytics and/or logging
- Basic anti-spam (honeypot + rate limiting)
- README updated with how to run + where data is stored

