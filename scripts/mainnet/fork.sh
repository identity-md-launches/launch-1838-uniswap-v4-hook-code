#!/usr/bin/env bash
set -euo pipefail
mkdir -p test/scratch
cleanup() {
  python3 - <<'PY_CLEANUP'
from pathlib import Path
Path("test/scratch/MainnetFork.t.sol").unlink(missing_ok=True)
PY_CLEANUP
}
trap cleanup EXIT
cp rehearsal/mainnet/MainnetFork.t.sol test/scratch/MainnetFork.t.sol
# Local fork only; no broadcast or public transaction. Signing uses the test's local deterministic key.
FOUNDRY_FUZZ_SEED=0xb992aebca039448ceb6aa325da16f06612255d105e125a5a7451b3928ec69e6e \
  forge test --match-path test/scratch/MainnetFork.t.sol -vv "$@"
