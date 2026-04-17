# EstateSale

EstateSale is an operator-first estate-sale platform. This repo now contains the first production-shaped scaffold for:

- `apps/ios`: Swift package-based seller app modules for intake, review, and fulfillment workflows
- `apps/admin-web`: Next.js + TypeScript operator/admin surface with backend-owned action routes
- `services/worker`: Python async worker for intake processing and provider jobs
- `supabase`: schema, policies, storage buckets, and seed data

## Build 1 Scope

- Photo intake and walkthrough intake
- Candidate item generation and review queue
- Review actions: approve, reject, group, fix
- eBay publish flow behind backend-owned adapters
- EasyPost shipping
- Uber Direct local delivery
- Pickup scheduling
- Duplicate-sale prevention via sibling listing closure

Out of scope in this repo state:

- Stale inventory and disposition workflows
- Mercari and Poshmark integrations beyond future planning artifacts
- Live provider credentials and production deployment wiring

## Repo Layout

```text
.
├── apps
│   ├── admin-web
│   └── ios
├── docs
│   └── plans
├── services
│   └── worker
├── supabase
│   ├── migrations
│   └── seed.sql
└── .github
    └── workflows
```

## Local Development

### Prerequisites

- Node 25+
- Python 3.14+
- Xcode 26+ with Swift 6.3+

### Install

```bash
npm install
python3 -m venv .venv
.venv/bin/python -m pip install -e "services/worker[dev]"
```

### Run Verification

```bash
npm run test
```

That root command runs:

- admin web unit tests
- worker unit tests
- Swift package tests

### Run the Admin Web App

```bash
npm run dev --workspace apps/admin-web
```

The admin app currently boots against a deterministic in-repo demo repository so the core review/publish/fulfillment rules can be exercised without live infrastructure. The Supabase schema is implemented in `supabase/`, but wiring the admin surface directly to that backend is still a follow-on step.

## Environment

Copy the admin web env template before running the app:

```bash
cp apps/admin-web/.env.example apps/admin-web/.env.local
```

Provider and Supabase secrets are intentionally not committed. The code in this repo is structured so provider calls stay behind adapters and can be tested with deterministic fixtures.

## Notes About iPhone App Structure

The repo does not include a generated `.xcodeproj`. Instead, `apps/ios` is an app-ready Swift package containing the domain layer, review workflow state, repository abstractions, and SwiftUI screens. That keeps the product logic testable in-repo and lets Xcode consume the package directly while the actual app shell is generated later.

## Planning Artifact

The plan currently being implemented is saved at [docs/plans/2026-04-16-estatesale-build-1.md](docs/plans/2026-04-16-estatesale-build-1.md).
