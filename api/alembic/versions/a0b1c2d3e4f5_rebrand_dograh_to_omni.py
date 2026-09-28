"""rebrand dograh -> omni: merge heads, rename quota columns, rewrite persisted provider value

Revision ID: a0b1c2d3e4f5
Revises: c7a1e4f93b26, cdcf9f65913b, f2e1d0c9b8a7
Create Date: 2026-09-27 20:00:00.000000

This migration is part of the dograh -> omni rebrand (sub-task 1.8, "Option 2":
the persisted provider value is changed on the wire, not just in code).

It does three things:

1. MERGE the three open alembic heads (c7a1e4f93b26, cdcf9f65913b,
   f2e1d0c9b8a7) into a single new head.

2. RENAME the `*_dograh_tokens` physical columns to `*_omni_tokens`:
     - organizations.quota_dograh_tokens        -> quota_omni_tokens   (deprecated)
     - organization_usage_cycles.quota_dograh_tokens -> quota_omni_tokens (deprecated)
     - organization_usage_cycles.used_dograh_tokens  -> used_omni_tokens
   These are plain Postgres column renames (no batch ops; matches env.py).

3. REWRITE the persisted provider value inside the model-configuration JSON so
   existing organizations keep working after the code starts emitting/expecting
   "omni":
     - organization_configurations.value (key = 'MODEL_CONFIGURATION_V2'):
         $.mode        "dograh" -> "omni"
         rename object key  $.dograh -> $.omni
     - both organization_configurations.value and legacy
       user_configurations.configuration: any nested service section
         $.{llm,tts,stt,embeddings,realtime}.provider "dograh" -> "omni"
   The rewrite is done in raw Python/JSON without importing application code
   (same discipline as 00b0201ad918), so it stays stable as the app evolves.

The downgrade reverses all three steps.
"""

import json
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "a0b1c2d3e4f5"
down_revision: Union[str, Sequence[str], None] = (
    "c7a1e4f93b26",
    "cdcf9f65913b",
    "f2e1d0c9b8a7",
)
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


_SERVICE_SECTIONS = ("llm", "tts", "stt", "embeddings", "realtime")


# --- column renames -------------------------------------------------------

def _rename_columns(mapping: list[tuple[str, str, str]]) -> None:
    for table, old, new in mapping:
        op.alter_column(table, old, new_column_name=new)


_COLUMN_RENAMES_UP = [
    ("organizations", "quota_dograh_tokens", "quota_omni_tokens"),
    ("organization_usage_cycles", "quota_dograh_tokens", "quota_omni_tokens"),
    ("organization_usage_cycles", "used_dograh_tokens", "used_omni_tokens"),
]
_COLUMN_RENAMES_DOWN = [(t, new, old) for (t, old, new) in _COLUMN_RENAMES_UP]


# --- persisted JSON rewrite ----------------------------------------------

def _rewrite_config_value(value: dict, *, old: str, new: str) -> tuple[dict, bool]:
    """Rewrite provider/mode strings in one model-configuration JSON value.

    Returns (new_value, changed). Only touches keys that are part of the
    model-configuration shape; lease/lock rows (which use the same column but
    a different shape) are left untouched because they have no mode/provider/
    <old> keys.
    """
    changed = False
    if not isinstance(value, dict):
        return value, False

    # V2 shape: {"version": 2, "mode": "dograh"|"byok", "dograh": {...}, "byok": {...}}
    if value.get("mode") == old:
        value["mode"] = new
        changed = True
    if old in value and new not in value:
        value[new] = value.pop(old)
        changed = True

    # Legacy / effective shape: nested service sections with a "provider".
    for section_name in _SERVICE_SECTIONS:
        section = value.get(section_name)
        if isinstance(section, dict) and section.get("provider") == old:
            section["provider"] = new
            changed = True

    # BYOK nested realtime/pipeline sections may also carry provider strings.
    byok = value.get("byok")
    if isinstance(byok, dict):
        for container_key in ("realtime", "pipeline"):
            container = byok.get(container_key)
            if isinstance(container, dict):
                for section_name in _SERVICE_SECTIONS:
                    section = container.get(section_name)
                    if isinstance(section, dict) and section.get("provider") == old:
                        section["provider"] = new
                        changed = True

    return value, changed


def _rewrite_table(connection, *, table: str, id_col: str, json_col: str,
                   key_col: str | None, key_values: tuple[str, ...] | None,
                   old: str, new: str) -> int:
    where = ""
    if key_col and key_values:
        placeholders = ", ".join(f":k{i}" for i in range(len(key_values)))
        where = f" WHERE {key_col} IN ({placeholders})"
    select_sql = f"SELECT {id_col} AS id, {json_col} AS val FROM {table}{where}"
    params = {f"k{i}": kv for i, kv in enumerate(key_values or ())}
    rows = connection.execute(sa.text(select_sql), params).mappings().all()

    update_sql = sa.text(
        f"UPDATE {table} SET {json_col} = CAST(:val AS json) WHERE {id_col} = :id"
    )
    updated = 0
    for row in rows:
        value = row["val"]
        if isinstance(value, str):
            try:
                value = json.loads(value)
            except ValueError:
                continue
        if not isinstance(value, dict):
            continue
        new_value, changed = _rewrite_config_value(value, old=old, new=new)
        if changed:
            connection.execute(update_sql, {"val": json.dumps(new_value), "id": row["id"]})
            updated += 1
    return updated


def _rewrite_all(old: str, new: str) -> None:
    connection = op.get_bind()
    org = _rewrite_table(
        connection,
        table="organization_configurations",
        id_col="id",
        json_col="value",
        key_col="key",
        key_values=("MODEL_CONFIGURATION_V2", "MODEL_CONFIGURATION"),
        old=old,
        new=new,
    )
    usr = _rewrite_table(
        connection,
        table="user_configurations",
        id_col="id",
        json_col="configuration",
        key_col="key",
        key_values=("MODEL_CONFIGURATION",),
        old=old,
        new=new,
    )
    print(
        f"Rewrote provider value '{old}'->'{new}' in "
        f"{org} organization_configurations row(s) and {usr} user_configurations row(s)"
    )


def upgrade() -> None:
    _rename_columns(_COLUMN_RENAMES_UP)
    _rewrite_all(old="dograh", new="omni")


def downgrade() -> None:
    _rewrite_all(old="omni", new="dograh")
    _rename_columns(_COLUMN_RENAMES_DOWN)
