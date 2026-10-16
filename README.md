# UNLOCK / UNLK — mainnet source candidate, release blocked

**Oracle redesign (this revision, continuing `8f31511e2b0d27d7c59b8bb33aeb65aeb3ae6ed6`):** the active candidate price source is now the pool-derived, no-paid-feed `ImdSampledUsdSource`: official UNLK/IMD hook TWAP × permissionless **sampled** IMD/native-ETH v4 pool price × validated Chainlink ETH/USD, FDV = 1B × USD/UNLK. Setup no longer admits the per-block proof source, so no ~10 ETH/day proof collector is a release requirement; a keeper must still call `sample()` at least every 20 minutes (normal gas, ~0.007 ETH/day at an illustrative 1 gwei). The preview site shows a pool-derived spot price/indicative FDV with block, sources, freshness and unavailable states. Manipulation tests show flash/same-block and anchor attacks are contained, but **repeated or sustained manipulation passes, and a modelled final-bypass attack with attacker-owned LP nets profit**: the oracle High remains open, H-01 remains High, independent review of these changes is **pending**, and deployment stays blocked. See [SAMPLED_ORACLE.md](docs/mainnet/revision/SAMPLED_ORACLE.md).

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
forge test --fuzz-seed 0x575e97c9f046cbe85a2214c324e8188fb0e71e67df58fe9dfbb5d33225f04312
forge fmt --check
python3 scripts/mainnet/artifacts.py --check
node web/scripts/typecheck-offline.mjs
node web/scripts/build-offline.mjs --test
(cd web && node --test ../test/scratch/frontend/*.test.mjs)
```

Network-dependent local rehearsal: `bash scripts/mainnet/fork.sh [RPC_URL]`. The public evidence source is `https://ethereum-rpc.publicnode.com`; no script signs or broadcasts. A read-only proxy transport may be needed on a sandboxed worker. Full oracle behavior tests are synthetic; actual mainnet proof and venue evidence are identified separately.

The task prohibits touching `.git/`, so this worker does not create or push a commit. The contributor upload step must publish the ordinary changed files and record that exact commit before final review. No commit or deployment success is fabricated. [Provenance](docs/mainnet/revision/PROVENANCE.json) records the public HEAD observed at the requested base.

Earlier generations remain under [docs/candidate](docs/candidate/), [docs/successor](docs/successor/) and the historical reports in [docs/mainnet](docs/mainnet/). The previous root README is retained [here](docs/mainnet/revision/README.pre-revision.md). Historical approvals/check logs do not approve this revision.
