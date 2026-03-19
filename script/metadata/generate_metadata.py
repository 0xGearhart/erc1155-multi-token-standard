#!/usr/bin/env python3
"""Generate deterministic ERC-1155 metadata JSON files.

- Input: metadata/source/items.json
- Output: metadata/build/<64-char-lower-hex-id>.json
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

REQUIRED_FIELDS = {"id", "name", "description", "image", "attributes"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate deterministic ERC-1155 metadata files")
    parser.add_argument("--source", default="metadata/source/items.json", help="Path to source items json array")
    parser.add_argument("--out", default="metadata/build", help="Output directory for generated metadata")
    return parser.parse_args()


def validate_item(item: dict, index: int) -> None:
    missing = REQUIRED_FIELDS - set(item.keys())
    if missing:
        raise ValueError(f"Item at index {index} missing required fields: {sorted(missing)}")

    token_id = item["id"]
    if not isinstance(token_id, int) or token_id < 0:
        raise ValueError(f"Item at index {index} has invalid id: {token_id}")

    if not isinstance(item["name"], str) or not item["name"].strip():
        raise ValueError(f"Item id {token_id} has invalid name")

    if not isinstance(item["description"], str):
        raise ValueError(f"Item id {token_id} has invalid description")

    if not isinstance(item["image"], str) or not item["image"].strip():
        raise ValueError(f"Item id {token_id} has invalid image")

    if not isinstance(item["attributes"], list):
        raise ValueError(f"Item id {token_id} has invalid attributes (must be array)")


def token_id_filename(token_id: int) -> str:
    # ERC-1155 {id}: lowercase hex, zero-padded to 64 chars, no 0x prefix.
    return f"{token_id:064x}.json"


def normalized_metadata(item: dict) -> dict:
    # Exclude `id` from token metadata body; id is represented by filename.
    return {
        "name": item["name"],
        "description": item["description"],
        "image": item["image"],
        "attributes": item["attributes"],
    }


def main() -> int:
    args = parse_args()
    source = Path(args.source)
    out_dir = Path(args.out)

    if not source.exists():
        raise FileNotFoundError(f"Source file not found: {source}")

    items = json.loads(source.read_text())
    if not isinstance(items, list):
        raise ValueError("Source file must contain a JSON array")

    seen_ids: set[int] = set()
    validated_items: list[dict] = []
    for idx, item in enumerate(items):
        if not isinstance(item, dict):
            raise ValueError(f"Item at index {idx} must be a JSON object")

        validate_item(item, idx)

        token_id = item["id"]
        if token_id in seen_ids:
            raise ValueError(f"Duplicate token id found: {token_id}")
        seen_ids.add(token_id)
        validated_items.append(item)

    out_dir.mkdir(parents=True, exist_ok=True)
    # Remove previously generated JSON files so removed token IDs do not linger in output.
    for old_json in out_dir.glob("*.json"):
        old_json.unlink()

    for item in sorted(validated_items, key=lambda x: x["id"]):
        token_id = item["id"]
        filename = token_id_filename(token_id)
        output_path = out_dir / filename
        output_path.write_text(
            json.dumps(normalized_metadata(item), sort_keys=True, separators=(",", ":"), ensure_ascii=True)
            + "\n"
        )

    manifest = {
        "count": len(validated_items),
        "ids": sorted(seen_ids),
        "source": str(source),
        "output_dir": str(out_dir),
    }
    (out_dir / "manifest.json").write_text(json.dumps(manifest, sort_keys=True, separators=(",", ":")) + "\n")

    print(f"Generated {len(validated_items)} metadata files in {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
