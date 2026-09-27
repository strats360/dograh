# Pipecat fork rebrand (sub-task 1.10)

The `pipecat` submodule points at the `dograh-hq/pipecat` fork. As part of the
`dograh → omni` rebrand, the `pipecat.services.dograh` service module must be
renamed to `pipecat.services.omni` and its classes `Dograh*` → `Omni*`.

> **Why a patch file instead of a pushed branch/PR?**
> The rebrand was performed and committed in a local clone of `dograh-hq/pipecat`,
> but this automation environment's GitHub credentials are scoped to
> `strats360/dograh` only. Forking `dograh-hq/pipecat` and pushing to it both
> return HTTP 403 here, so the change is delivered as a patch for a human/CI with
> the right permissions to publish.

## What the patch does

Applied on top of the currently pinned submodule commit
`2b2b9d5281a548ac1f8aa415c018b804c0cbc05b`, it:

- Renames the module directory `src/pipecat/services/dograh/` → `src/pipecat/services/omni/`
- Renames classes: `DograhLLMService`→`OmniLLMService`, `DograhSTTService`→`OmniSTTService`,
  `DograhTTSService`→`OmniTTSService`, `DograhFluxSTTService`→`OmniFluxSTTService`,
  `DograhSTTSettings`→`OmniSTTSettings`, `DograhTTSSettings`→`OmniTTSSettings`
- Renames constant `DOGRAH_TTFS_P`→`OMNI_TTFS_P` and private method `_build_dograh_query_string`→`_build_omni_query_string`
- Updates internal import paths `pipecat.services.dograh.*` → `pipecat.services.omni.*`
- Rebrands docstrings/comments/log prose `Dograh`→`Omni`
- **Leaves the `services.dograh.com` base URLs unchanged** — those move with the
  domain rename (coordinated with sub-task 1.9 / DNS), not the module rename.

## How to publish

1. Fork `dograh-hq/pipecat` to `strats360` (or your org) on GitHub — e.g.
   `gh repo fork dograh-hq/pipecat --org strats360` (needs fork permission).
2. Clone the fork and check out the pinned base commit:
   ```bash
   git clone https://github.com/strats360/pipecat.git
   cd pipecat
   git checkout -b rebrand/dograh-to-omni 2b2b9d5281a548ac1f8aa415c018b804c0cbc05b
   git am /path/to/0001-rename-dograh-services-module-to-omni.patch
   git push -u origin rebrand/dograh-to-omni
   ```
3. Merge that branch in the fork, then update this repo's submodule pin:
   ```bash
   cd dograh
   git submodule set-url pipecat https://github.com/strats360/pipecat.git   # already reflected in .gitmodules
   git submodule update --init --remote pipecat
   git -C pipecat checkout <new-omni-commit-sha>
   git add pipecat .gitmodules && git commit -m "chore(rebrand): point pipecat submodule at omni fork"
   ```

## Companion changes already made in this repo (this branch)

- `.gitmodules` submodule URL updated to `https://github.com/strats360/pipecat.git`.
- `api/services/pipecat/service_factory.py` imports updated to `pipecat.services.omni`
  and `Omni*` runtime classes.
- Test patch-target strings and imports updated (`test_camb_tts_integration.py`,
  `test_dograh_managed_correlation.py`, `test_dograh_llm_service_factory.py`,
  `test_dograh_stt_service_factory.py`, `test_service_factory_failure_reporting.py`).

> Note: the api side will not import successfully until the omni fork is published
> and the submodule pin is updated, because `pipecat.services.omni` only exists in
> the rebranded fork.
