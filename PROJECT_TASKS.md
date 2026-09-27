# Project Tasks

This document tracks the two active initiatives. It mirrors a project board: each sub-task
becomes its own Pull Request. Checkboxes are ticked as each PR is opened/merged.

Legend: `[ ]` todo · `[~]` in progress (PR open) · `[x]` done (merged)

---

## Epic 1 — Rebrand: `dograh` → `omni` (full)

**Branch:** `rebrand/dograh-to-omni` (sub-task branches fork from here; PRs target this branch, which finally targets `main`)

> Scope: FULL rename, including breaking/risky items. Risky items are called out so
> deployment/release owners can coordinate published-package and DB migration rollout.

- [ ] **1.1 — UI display text + app title/metadata**
  - `ui/src/**` display strings (~353), `ui/src/app/layout.tsx` title/metadata
- [ ] **1.2 — Logo & brand assets + references**
  - `ui/public/dograh-logo*.png`, `ui/public/dograh-mark.png`, `docs/images/*dograh*`, all `<img>`/import references
- [ ] **1.3 — Docs & READMEs prose**
  - `README.md`, `README.ja-JP.md`, `README.zh-CN.md`, `docs/**/*.mdx`, `SECURITY.md`
- [ ] **1.4 — Internal code class/module names (`Dograh*`)**
  - `api/services/configuration/registry.py` service classes, `DograhEmbeddingService`, `api/tests/test_dograh_*`
- [ ] **1.5 — Infra: docker-compose, helm, workflows, nginx, scripts** *(risky: deployed release names/labels)*
  - `docker-compose.yaml` services, `deploy/helm/dograh/`, `.github/workflows/docker-image.yml`, `nginx/`, `scripts/`
- [ ] **1.6 — Env var prefixes + headers** *(BREAKING: existing env files & callers)*
  - `DOGRAH_*` env vars (`api/constants.py`, `.env.example`), `X-Dograh-Devops-Secret` header
- [ ] **1.7 — Published package names** *(BREAKING: PyPI/npm consumers)*
  - PyPI `dograh-sdk`/`dograh-api`, npm `@dograh/sdk`, `dograh_sdk` module (~39 imports), `dograh-ts-validator`
- [~] **1.8 — DB identifiers + provider enum value + migration** *(BREAKING: requires data migration)* — **Option 2 (full)**
  - Changed provider enum `ServiceProviders.DOGRAH="dograh"`→`OMNI="omni"` (member + wire value) + all ~28 usages/literals; renamed `dograh_model`→`omni_model` API field; ORM/API token identifiers `*_dograh_tokens`/`dograh_token_usage`→`*_omni_tokens`/`omni_token_usage`; UI wire keys + local identifiers in `AIModelConfigurationV2Editor.tsx`.
  - **New alembic migration `a0b1c2d3e4f5`**: merges the 3 heads, renames the DB columns, and rewrites persisted JSON (`$.mode`, `$.dograh`→`$.omni`, nested `provider` values) in `organization_configurations`/`user_configurations`. Reversible. compileall passes.
  - Left/flagged (see `REBRAND_1.8_FOLLOWUPS.md`): MPS backend must accept `"omni"` + rename pricing key + `dograh_embedding_v1` model id; regenerate `ui/src/client/**` + `openapi.json`; external API consumers must update. Pipecat runtime classes stay `Dograh*` (1.10); external URLs (1.9).
- [ ] **1.9 — Auth cookies + domains + repo/external URLs** *(BREAKING: invalidates sessions)*
  - `dograh_auth_token`/`dograh_auth_user` cookies, `dograh.com`/`docs.dograh.com`, `github.com/dograh-hq/*`, embed widget `dograh-widget.js`

---

## Epic 2 — Complete UI/UX Revamp

**Branch:** `revamp/ui-ux` (sub-task branches fork from here; PRs target this branch, which finally targets `main`)

> Design-first: 2.1 produces a design proposal for approval BEFORE any implementation sub-task begins.

- [ ] **2.1 — UI/UX design proposal for review** (colors, typography, tokens, component look, shell layout) — *needs user approval*
- [ ] **2.2 — Implement approved design tokens & theme** (`ui/src/app/globals.css` — OKLCH tokens, type scale, radius)
- [ ] **2.3 — Revamp app shell** (`AppLayout`, `AppSidebar`, `AppHeader` chrome)
- [ ] **2.4 — Restyle shadcn/ui primitives** (`ui/src/components/ui/**` — cascades app-wide)
- [ ] **2.5 — Rework bespoke branded CSS + feature-page polish** (sidebar dock, card weave, brand imprint, auth waveform; overview/workflow/campaigns/settings)

---

## Environment note

GitHub Projects (V2) and Issues are unavailable in this workspace (GraphQL pass-through is
disabled; repo Issues are turned off), so this file + one PR per sub-task is the tracking mechanism.
