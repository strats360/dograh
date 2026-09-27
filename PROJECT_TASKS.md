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
- [~] **1.4 — Internal code class/module names (`Dograh*`)**
  - Renamed ~18 `api/`-owned classes + config models (`OmniEmbeddingService`, `OmniLLMService`/`OmniTTSService`/`OmniSTTService` in `registry.py`, realtime wrappers, adapters, `OmniManagedAIModelConfiguration`, `OmniFailure`) and internal `OMNI_*` constants. Renamed log tag `DOGRAH_FAILURE`→`OMNI_FAILURE`. Moved 4 `test_dograh_*`→`test_omni_*`. `compileall` (py3.13) passes.
  - Left pipecat-fork runtime classes (`pipecat.services.dograh.*`) as `Dograh*` — now handled in **1.10** (fork rebrand). Deferred: provider enum (1.8), env vars/headers (1.6), SDK types (1.7), DB fields (1.8).
- [ ] **1.5 — Infra: docker-compose, helm, workflows, nginx, scripts** *(risky: deployed release names/labels)*
  - `docker-compose.yaml` services, `deploy/helm/dograh/`, `.github/workflows/docker-image.yml`, `nginx/`, `scripts/`
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

- [ ] **1.10 — Fork & rebrand `dograh-hq/pipecat` submodule** *(added per request)*
  - Fork/clone the pipecat submodule, rename `pipecat.services.dograh.*` runtime classes (`DograhLLMService`, `DograhTTSService`, `DograhSTTService`, `DograhFluxSTTService`, settings) to `Omni*`, update `.gitmodules` URL + api import sites.

---

## Environment note

GitHub Projects (V2) and Issues are unavailable in this workspace (GraphQL pass-through is
disabled; repo Issues are turned off), so this file + one PR per sub-task is the tracking mechanism.
