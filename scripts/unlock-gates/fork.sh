#!/usr/bin/env bash
set -euo pipefail
# Local fork tests only. Explicit public RPC override; no environment, wallet, signing or broadcast.
rpc_url="${1:-https://eth.drpc.org}"
if [ "$#" -gt 0 ]; then shift; fi
mkdir -p test/scratch/unlock-gates
trap 'rm -f test/scratch/unlock-gates/MainnetHandoff.t.sol' EXIT
python3 - "$rpc_url" <<'PY'
from pathlib import Path
import sys
from urllib.parse import urlparse
url = sys.argv[1]
parsed = urlparse(url)
if parsed.scheme not in ("http", "https") or not parsed.netloc:
    raise SystemExit("Explicit HTTP(S) RPC URL required")
if any(c in url for c in ['"', '\\', '\n', '\r']):
    raise SystemExit('Invalid RPC URL')
p = Path('rehearsal/unlock-gates/MainnetHandoff.t.sol')
Path('test/scratch/unlock-gates/MainnetHandoff.t.sol').write_text(p.read_text().replace('https://ethereum-rpc.publicnode.com', url))
PY
forge test --match-path 'test/scratch/unlock-gates/MainnetHandoff.t.sol' \
  --fuzz-seed 0xda8bb4c7a1dfecbe1d2824491108f08053450070bcb18434381100e02a366653 -vv "$@"
