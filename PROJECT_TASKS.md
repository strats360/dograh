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


---

## Epic 1 — Rebrand: status = ALL SUB-TASKS COMPLETE ✅

One PR per sub-task, all targeting `rebrand/dograh-to-omni`:

| Sub-task | PR |
|---|---|
| 1.1 UI display text + title | #1 |
| 1.2 Brand assets | #2 |
| 1.3 Docs & README prose | #3 |
| 1.4 Internal code identifiers | #4 |
| 1.10 Pipecat fork rebrand (patch; fork blocked in sandbox) | #5 |
| 1.5 Infra (helm/compose/workflows/nginx/scripts) | #6 |
| 1.6 Env vars + headers | #7 |
| 1.7 SDK package names | #8 |
| 1.8 DB columns + provider value + data migration | #9 |
| 1.9 Auth cookies + domains + embed widget | #10 |

### End-to-end validation (branch `rebrand/integration-test` = all 10 merged)
- Integrated all 10 sub-task branches into one branch; resolved cross-branch conflicts
  (docs image path + prose, infra + env vars, SDK + prose, 1.4/1.8 class overlaps,
  domains + env vars). **No conflict markers remain.**
- **Full api compiles** (`compileall`, Python 3.13) with the rebranded pipecat `omni`
  module in place.
- **Data migration validated** (imported + exercised): correct 3-head merge; upgrade
  rewrites `mode`, `dograh`→`omni` object key, and nested `provider` values; downgrade
  round-trips; lease/lock rows left untouched.
- Embed widget `omni-widget.js` passes `node --check`.
- **UI typecheck: PASS.** After installing deps (`npm install` completes in ~13s with a
  warm cache in a single call; earlier attempts only "failed" by hitting the 120s per-command
  tool timeout with a cold cache — not a code error), `tsc --noEmit -p tsconfig.json` reports
  **0 errors in the rebranded UI source**. The only tsc error anywhere is a pre-existing
  syntax glitch inside the `@hey-api/spec-types` dependency's `.d.mts` (excluded by the
  project tsconfig) — unrelated to the rebrand.
- `next build` crashes (exit 135, no output) under the sandbox's Next 15 native binary
  (not OOM — 28Gi free); **run the full `next build` in CI** on `rebrand/integration-test`.

### Outstanding coordination (see `REBRAND_1.8_FOLLOWUPS.md` + `pipecat-rebrand/README.md`)
- Publish the rebranded **pipecat fork** (patch provided) and re-pin the submodule.
- **MPS backend**: accept provider `"omni"`, rename pricing key `dograh_model`→`omni_model`,
  coordinate `dograh_embedding_v1` model id.
- **Regenerate** `ui/src/client/**` + `docs/api-reference/openapi.json` from the updated api.
- **DNS**: `*.omni.com` hosts must exist. Run `alembic upgrade head` on deploy.
- External resources intentionally left (GitHub `dograh-hq` repo/org, Slack invite, Axiom
  tenant, `dograhai` registry) require account/DNS-level renames outside the codebase.
