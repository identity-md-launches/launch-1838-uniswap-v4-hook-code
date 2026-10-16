# UNLOCK / UNLK — mainnet source candidate, release blocked

This continues `18062fc08c2fc3ab47b79316c1d1dea701e36e7f`. It preserves the live launch1560 contracts/configuration and prior candidate history. No public transaction, deployment, token replacement or site publication was performed. Candidate writes remain disabled and the NFT gallery stays read-only.

The mainnet target remains IMD `univ4_hook`, 1B UNLK / 18 decimals, 10/87/3 allocation, standard Universal Router compatibility, official 1.25% fee plus 75 bps in IMD to the fixed beneficiary, protected seed principal and the existing sixteen sequential USD tiers with permanent final bypass.

This revision implements:

- One-block maturity for new buy credit across every router call/UI, without redefining cumulative E or transferring rights. Claims/payer credits and ordinary transfers remain independent.
- An optional immutable wallet-scoped executor that uses the standard router, pulls only from its authenticated caller, fixes settlement to that wallet and retains its own separate E/S ledger. Direct wallets and legitimate smart accounts still trade normally.
- A noncircular IMD/USD source that authenticates every consecutive block's v4 price/depth using Ethereum headers and account/storage proofs, then composes 2h/24h history with Chainlink ETH/USD. The inactive v3 reader is no longer admitted as the production source.
- Regression, fuzz, invariant and actual recorded-mainnet tests, a disabled preview, unsigned oracle/stage2 preparation and an updated release handoff.

**H-01 remains High:** mature rights at a shared executor can still be consumed by another user supplying their own tokens. The on-chain reductions do not resolve global beneficial-user identity. **Oracle release is also blocked:** the observed market fails the depth screen, full real history is absent, and sustained manipulation cost is not independently established. Final changes are pending independent review.

Read the [readiness matrix and exact blockers](docs/mainnet/revision/READINESS.md), [H-01 proof and reductions](docs/mainnet/revision/H-01.md), [oracle evidence, interval proof and economics](docs/mainnet/revision/ORACLE.md), and [two-stage deployment/postflight specification](docs/mainnet/DEPLOYMENT.md). The [release plan](docs/mainnet/release-plan.json) is a source handoff, not a launch manifest. The existing root launch manifest describes the historical project.

Build and verify offline with the unchanged pinned Solidity 0.8.26 configuration:

```sh
forge build
forge test --fuzz-seed 0x1d49232a44ff2493b73de50672c825b51c99d7c5f9f966576d2050bd2684d532
forge fmt --check
python3 scripts/mainnet/artifacts.py --check
node web/scripts/typecheck-offline.mjs
node web/scripts/build-offline.mjs --test
(cd web && node --test ../test/scratch/frontend/*.test.mjs)
```

Network-dependent local rehearsal: `bash scripts/mainnet/fork.sh [RPC_URL]`. The public evidence source is `https://ethereum-rpc.publicnode.com`; no script signs or broadcasts. A read-only proxy transport may be needed on a sandboxed worker. Full oracle behavior tests are synthetic; actual mainnet proof and venue evidence are identified separately.

The task prohibits touching `.git/`, so this worker does not create or push a commit. The contributor upload step must publish the ordinary changed files and record that exact commit before final review. No commit or deployment success is fabricated. [Provenance](docs/mainnet/revision/PROVENANCE.json) records the public HEAD observed at the requested base.

Earlier generations remain under [docs/candidate](docs/candidate/), [docs/successor](docs/successor/) and the historical reports in [docs/mainnet](docs/mainnet/). The previous root README is retained [here](docs/mainnet/revision/README.pre-revision.md). Historical approvals/check logs do not approve this revision.
