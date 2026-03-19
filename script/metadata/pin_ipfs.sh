#!/usr/bin/env bash
set -euo pipefail

INPUT_DIR="${1:-metadata/build}"

if ! command -v ipfs >/dev/null 2>&1; then
  echo "ipfs CLI not found. Install IPFS (Kubo) first." >&2
  exit 1
fi

if [ ! -d "$INPUT_DIR" ]; then
  echo "metadata folder not found: $INPUT_DIR" >&2
  exit 1
fi

CID="$(ipfs add -Qr "$INPUT_DIR")"
BASE_URI="ipfs://${CID}/{id}.json"

echo "CID: ${CID}"
echo "Base URI: ${BASE_URI}"

echo "$CID" > metadata/CID.latest
