# Sub-task 1.8 — required follow-ups & coordination (Option 2, breaking)

Sub-task 1.8 changed the **persisted provider value** `"dograh"` → `"omni"` and renamed
the `dograh_model` API field and `*_dograh_tokens` DB columns. The following items live
**outside this repo/branch** and MUST be coordinated for the rebrand to work end-to-end.

## 1. Database migration (in this repo, must run on deploy)
- New migration: `api/alembic/versions/a0b1c2d3e4f5_rebrand_dograh_to_omni.py`
  - Merges the 3 alembic heads (`c7a1e4f93b26`, `cdcf9f65913b`, `f2e1d0c9b8a7`).
  - Renames columns `quota_dograh_tokens`→`quota_omni_tokens` (organizations + organization_usage_cycles) and `used_dograh_tokens`→`used_omni_tokens`.
  - Rewrites persisted JSON in `organization_configurations.value` and legacy `user_configurations.configuration`: `$.mode "dograh"→"omni"`, key `$.dograh`→`$.omni`, and nested `$.{llm,tts,stt,embeddings,realtime}.provider "dograh"→"omni"`.
  - Fully reversible (`downgrade` reverses both the JSON rewrite and the column renames).
- **Run `alembic upgrade head` as part of the release** so existing orgs keep working the moment the code starts emitting/expecting `"omni"`.

## 2. MPS backend (separate service — out of this repo)
- **Provider value**: the MPS proxy must accept/emit provider `"omni"` (was `"dograh"`) for LLM/TTS/STT/embeddings routing.
- **Billing pricing payload key**: MPS must rename the response key `dograh_model` → `omni_model`; `ModelConfigurationPricingResponse.omni_model` is populated via `model_validate(pricing)` and won't populate otherwise.
- **Model id `dograh_embedding_v1`**: intentionally **left unchanged** in code — it is a model identifier the MPS backend resolves. Rename it in BOTH places together in a coordinated change, or leave as-is.

## 3. Regenerate the API client (in this repo, after api merges)
- `ui/src/client/**` (`types.gen.ts`, `sdk.gen.ts`) and `docs/api-reference/openapi.json` are **generated** and were intentionally NOT hand-edited. After the api changes land, run:
  ```bash
  cd ui && npm run generate-client
  ```
  so the generated types carry `omni`, `omni_model`, `omni_token_usage`, `used_omni_tokens`, `X-Omni-Devops-Secret`, etc. (this also picks up the 1.6 header rename). Requires the api running locally.

## 4. External API consumers
- Any external client that sends/reads the model-configuration provider value, the pricing `dograh_model` field, or the usage `*_dograh_tokens`/`dograh_token_usage` fields must update to the `omni_*` names. This is a **breaking API change**.
