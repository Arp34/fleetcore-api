# FleetCore API

REST API to manage the lifecycle of preventive and corrective maintenance for the FleetCore vehicle fleet.

**Stack:** NestJS 12 · TypeScript · TypeORM · PostgreSQL 17 · JWT · Swagger · Docker · Vitest

## 👤 Coder

- **Name:** Axel Ruiz Polo
- **Clan:** Centurion
- **GitHub:** [@Arp34](https://github.com/Arp34)
- **Email:** axeldrp3407@gmail.com

## 🚀 Requirements

- Node.js 24 LTS
- Docker and Docker Compose

## ⚙️ Installation and running

```bash
# 1. Clone and install dependencies
git clone https://github.com/Arp34/fleetcore-api.git
cd fleetcore-api
npm install

# 2. Environment variables
cp .env.example .env

# 3. Start PostgreSQL
docker compose up -d db

# 4. Seed the database (idempotent: can be run several times without duplicating data)
npm run seed

# 5. Start the API in development mode
npm run start:dev
```

API: `http://localhost:3000/api`

### Docker option (API + PostgreSQL)

```bash
cp .env.example .env
docker compose up -d --build db api
docker exec fleetcore_api node dist/database/seed.js
```

The API and the database communicate through the internal `fleetcore-net` network, and data persists in the `pgdata` volume.

## 🔐 Environment variables

| Variable | Description | Example |
|---|---|---|
| `PORT` | API port | `3000` |
| `DB_HOST` / `DB_PORT` | PostgreSQL host and port | `localhost` / `5433` |
| `DB_USERNAME` / `DB_PASSWORD` | PostgreSQL credentials | `postgres` / `postgres` |
| `DB_NAME` | Database name | `fleetcore` |
| `DB_SYNC` | Syncs the schema with the entities (development only) | `true` |
| `JWT_SECRET` | Secret used to sign tokens (min. 16 characters) | `cambia-este-secreto-...` |
| `JWT_EXPIRES_IN` | Token lifetime | `1h` |
| `API_KEYS` | Valid keys for integrations, comma-separated | `demo-key-partner-1,demo-key-partner-2` |

## 📚 Swagger documentation

**`http://localhost:3000/docs`**

1. Call `POST /api/auth/login` with one of the test credentials.
2. Copy the `accessToken` and paste it in **Authorize → bearer**.
3. For the integrations endpoint, use **Authorize → api-key** with `demo-key-partner-1`.

## 🔑 Test credentials (seed)

| Role | Email | Password | Linked mechanic |
|---|---|---|---|
| ADMIN | `admin@fleetcore.com` | `Admin12345` | — |
| TECHNICIAN | `carlos.perez@fleetcore.com` | `Tecnico123` | Carlos Pérez |
| TECHNICIAN | `laura.gomez@fleetcore.com` | `Tecnico123` | Laura Gómez |

Integration API Key: `demo-key-partner-1`

### Seeded data

- **Users:** 1 ADMIN and 2 TECHNICIAN.
- **Mechanics:** Carlos Pérez and Laura Gómez (active, linked to the technicians) and Pedro Ruiz (inactive).
- **Workshops:** Taller Centro (active) and Taller Norte (inactive).
- **Vehicles:** `ABC123` and `DEF456` (AVAILABLE), `GHI789` (IN_MAINTENANCE) and `JKL012` (INACTIVE).
- **Maintenances:** 2 COMPLETED for `ABC123` (history), 1 IN_PROGRESS for `GHI789` and 1 SCHEDULED for `DEF456`, each with its audit trail.

## 🧭 Main endpoints

All routes use the `/api` prefix.

| Resource | Method and route | Role |
|---|---|---|
| Auth | `POST /auth/register` (creates TECHNICIAN) · `POST /auth/login` | Public |
| Users | `POST /users` (any role) · `GET /users` · `GET /users/:id` | ADMIN |
| | `GET /users/me` | Authenticated |
| Vehicles | `POST /vehicles` · `PATCH /vehicles/:id` · `DELETE /vehicles/:id` (deactivates) · `PATCH /vehicles/:id/activate` | ADMIN |
| | `GET /vehicles` · `GET /vehicles/:id` · `GET /vehicles/plate/:plate` | Authenticated |
| Mechanics | `POST /mechanics` · `PATCH /mechanics/:id` · `PATCH /mechanics/:id/activate` · `PATCH /mechanics/:id/deactivate` | ADMIN |
| | `GET /mechanics?isActive=` · `GET /mechanics/:id` | Authenticated |
| | `GET /mechanics/me` (own mechanic profile) | TECHNICIAN |
| Workshops | `POST /workshops` · `PATCH /workshops/:id` · `GET /workshops/all` · `PATCH /workshops/:id/activate` · `PATCH /workshops/:id/deactivate` | ADMIN |
| | `GET /workshops` (active only) · `GET /workshops/:id` | Authenticated |
| Maintenances | `POST /maintenances` · `GET /maintenances` · `GET /maintenances/active` · `GET /maintenances/vehicle/:vehicleId` · `GET /maintenances/vehicle/:vehicleId/history` · `GET /maintenances/mechanic/:mechanicId` · `GET /maintenances/audit` · `GET /maintenances/:id/audit` | ADMIN |
| | `GET /maintenances/my` | TECHNICIAN |
| | `GET /maintenances/:id` · `PATCH /maintenances/:id/status` | ADMIN or assigned technician |
| Integrations | `GET /integrations/vehicles/:plate/history` | `x-api-key` header |

## 📏 Business rules

- Maintenances cannot be created for vehicles, mechanics or workshops that don't exist (404) or are inactive (409).
- A vehicle cannot have more than one active maintenance (`SCHEDULED` or `IN_PROGRESS`).
- A mechanic cannot have active maintenances with overlapping schedules, in any workshop. Each maintenance has `scheduledAt` and `durationMinutes`; back-to-back slots are allowed (7:30–9:00 and 9:00–10:00).
- A mechanic can only have one `IN_PROGRESS` maintenance at a time.
- The maintenance mileage cannot be lower than the vehicle's current mileage.
- Allowed transitions: `SCHEDULED → IN_PROGRESS | CANCELLED` and `IN_PROGRESS → COMPLETED | CANCELLED`. `COMPLETED` and `CANCELLED` are final states (409).
- `IN_PROGRESS` sets the vehicle to `IN_MAINTENANCE`. `COMPLETED` requires `workPerformed`, `finalCost`, `finishedAt` and `finalMileage`, sets the vehicle back to `AVAILABLE` and updates its mileage.
- Creation and status changes run inside transactions with row locking (`SELECT ... FOR UPDATE`).
- Every status change is audited (`maintenance_status_logs`): who changed it, from which status, to which status and when.
- When a maintenance starts, the vehicle, mechanic and workshop are checked again (they may have been deactivated after scheduling).
- Uniform success responses (`TransformInterceptor`) and uniform errors (`AllExceptionsFilter`), including database errors, with no 500 responses.

## 🧪 Tests and evidence

```bash
npm run test          # unit tests with Vitest (Jest-compatible API): status rules and auth
npm run test:cov      # coverage
npm run test:e2e      # e2e (requires: docker compose up -d db_test)
```

- **Postman collection:** [`postman/FleetCore.postman_collection.json`](postman/FleetCore.postman_collection.json). Import it and run it in order with the *Collection Runner* after `npm run seed`; it covers the main scenarios with automated tests. It can also be run from the terminal with `npx newman run postman/FleetCore.postman_collection.json`.
- **Database dump:** [`database/fleetcore_dump.sql`](database/fleetcore_dump.sql), with the schema and seeded data. To restore it: `psql -U postgres -d fleetcore -f database/fleetcore_dump.sql`.
