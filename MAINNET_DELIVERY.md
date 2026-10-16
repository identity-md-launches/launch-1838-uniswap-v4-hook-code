# Mainnet UNLK/IMD mitigation candidate

## Revision: pool-derived sampled oracle (current)

Implemented locally: `ImdSampledUsdSource` (permissionless sampled IMD/ETH v4 pool × Chainlink ETH/USD, 50-tick/min clamp, 1m–20m sampling, 250 virtual-ETH liveness screen, 48h cold start, min(2h,24h), zero weight for the latest sample, no admin) is the only source `deployPriceSource` admits; the proof source is historical. Website preview shows spot USD/IMD, USD/UNLK and indicative FDV (unavailable until the successor pool exists) with block/sources/freshness. **Full Foundry suite: 345 passed** with seed `0x575e97c9…4312`; pinned build and `forge fmt --check` passed; frontend typecheck/build and 28 tests passed. Measured limitation: repeated/sustained manipulation passes; a modelled final-bypass attack with attacker-owned LP costs ≈$103k against ≈$500k realizable value (synthetic model). The oracle High and H-01 High remain; independent review is pending; no deployment, commit or publication was performed by this worker. Details: [SAMPLED_ORACLE.md](docs/mainnet/revision/SAMPLED_ORACLE.md).

## Previous revision (historical)

Implemented and tested locally. **Release remains blocked:** independent H-01 is still High for mature shared quotas, production oracle economics/history/depth remain insufficient, and independent review of the final changes is pending. No public transaction, deployment, token replacement or publication occurred.

The revision adds one-block buy-credit maturity, an optional immutable single-wallet executor with caller-only token pulls and separate E/S, and an authenticated per-block v4 IMD/ETH source composed with Chainlink ETH/USD. The inactive v3 reader is no longer admitted. The proof source rejects missing history/depth; it does not claim that a long authenticated price is necessarily safe against sustained manipulation.

The standard router, legitimate smart accounts, ordinary transfers/native claims, fixed fees, beneficiary, principal and sixteen milestones remain supported. Candidate writes stay disabled; the gallery remains read-only. Live launch1560 configuration and historical source/checkers/dependencies are preserved.

See [readiness and exact blockers](docs/mainnet/revision/READINESS.md), [H-01 reductions and capacity proof](docs/mainnet/revision/H-01.md), [real versus synthetic oracle evidence and costs](docs/mainnet/revision/ORACLE.md), [two-stage/postflight handoff](docs/mainnet/DEPLOYMENT.md), and [creation commitments/ABIs](docs/mainnet/ARTIFACTS.json).

Final offline results: **329 Foundry tests passed** with the supplied seed; pinned-solc build and formatting passed. Frontend typecheck/build and **24 tests passed**. **27 actual-mainnet recorded-block tests passed**; their scope are recorded in `docs/mainnet/revision/fork-tests.txt`. Protected harness/browser skips are explicit; author checks carry no independent authority.

The uploader must publish the changed ordinary files and record the exact accepted commit; this task prohibits `.git` changes. No commit, review, full production oracle history or deployment success is invented. Current source hashes are in `docs/mainnet/revision/SOURCE_SHA256SUMS`; older reports/hashes describe their respective historical deliveries.
