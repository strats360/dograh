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
- [~] **1.5 — Infra: docker-compose, helm, workflows, nginx, scripts** *(risky: deployed release names/labels)*
  - Renamed helm chart `deploy/helm/dograh`→`omni` (29 template defines `dograh.*`→`omni.*`, all includes atomic), image names `dograh-{api,ui}`→`omni-{api,ui}` (registry `dograhai` kept), compose `dograh-init`→`omni-init`, `nginx/dograh_upstream`→`omni_upstream`, `scripts/run_dograh_init.sh`→`run_omni_init.sh`, `dograh_*` shell fns→`omni_*`, coupled `__DOGRAH_*__` template placeholders→`__OMNI_*__`, MinIO user prefix, letsencrypt hook, workflow image names. YAML validated; 64+ files.
  - Left (other sub-tasks): `dograhai` registry & `dograh-hq` URLs (1.9), `DOGRAH_*` env vars + `X-Dograh-*` header (1.6), SDK org/pkg names + conda env (1.7), release tag prefix `dograh-v*` & CI secret `SLACK_DOGRAH_*` (release automation), repo clone-dir name `dograh` (repo rename).
- [ ] **1.6 — Env var prefixes + headers** *(BREAKING: existing env files & callers)*
  - `DOGRAH_*` env vars (`api/constants.py`, `.env.example`), `X-Dograh-Devops-Secret` header
- [ ] **1.7 — Published package names** *(BREAKING: PyPI/npm consumers)*
  - PyPI `dograh-sdk`/`dograh-api`, npm `@dograh/sdk`, `dograh_sdk` module (~39 imports), `dograh-ts-validator`
- [ ] **1.8 — DB identifiers + provider enum value + migration** *(BREAKING: requires data migration)*
  - `dograh_tokens`/`used_dograh_tokens`/`quota_dograh_tokens` columns, `ServiceProviders.DOGRAH="dograh"` value, new alembic migration, regenerate openapi/types
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

- [~] **1.10 — Fork & rebrand `dograh-hq/pipecat` submodule** *(added per request)*
  - Rebranded the pipecat service module in a local clone: `services/dograh`→`services/omni`, `Dograh*`→`Omni*` classes, `OMNI_TTFS_P`, import paths, prose (kept `services.dograh.com` URLs for domain move). Committed locally; delivered as a patch in `pipecat-rebrand/` because forking/pushing `dograh-hq/pipecat` is blocked (HTTP 403 — creds scoped to `strats360/dograh`).
  - dograh-side: updated `.gitmodules` URL → `strats360/pipecat`, api `service_factory.py` + tests to `pipecat.services.omni`/`Omni*`. **Blocker:** api won't import until the fork is published & submodule re-pinned (see `pipecat-rebrand/README.md`).

---

## Environment note

GitHub Projects (V2) and Issues are unavailable in this workspace (GraphQL pass-through is
disabled; repo Issues are turned off), so this file + one PR per sub-task is the tracking mechanism.
