# Mainnet UNLK/IMD mitigation candidate

Implemented and tested locally. **Release remains blocked:** independent H-01 is still High for mature shared quotas, production oracle economics/history/depth remain insufficient, and independent review of the final changes is pending. No public transaction, deployment, token replacement or publication occurred.

The revision adds one-block buy-credit maturity, an optional immutable single-wallet executor with caller-only token pulls and separate E/S, and an authenticated per-block v4 IMD/ETH source composed with Chainlink ETH/USD. The inactive v3 reader is no longer admitted. The proof source rejects missing history/depth; it does not claim that a long authenticated price is necessarily safe against sustained manipulation.

The standard router, legitimate smart accounts, ordinary transfers/native claims, fixed fees, beneficiary, principal and sixteen milestones remain supported. Candidate writes stay disabled; the gallery remains read-only. Live launch1560 configuration and historical source/checkers/dependencies are preserved.

See [readiness and exact blockers](docs/mainnet/revision/READINESS.md), [H-01 reductions and capacity proof](docs/mainnet/revision/H-01.md), [real versus synthetic oracle evidence and costs](docs/mainnet/revision/ORACLE.md), [two-stage/postflight handoff](docs/mainnet/DEPLOYMENT.md), and [creation commitments/ABIs](docs/mainnet/ARTIFACTS.json).

Final offline results: **329 Foundry tests passed** with the supplied seed; pinned-solc build and formatting passed. Frontend typecheck/build and **24 tests passed**. **27 actual-mainnet recorded-block tests passed**; their scope are recorded in `docs/mainnet/revision/fork-tests.txt`. Protected harness/browser skips are explicit; author checks carry no independent authority.

The uploader must publish the changed ordinary files and record the exact accepted commit; this task prohibits `.git` changes. No commit, review, full production oracle history or deployment success is invented. Current source hashes are in `docs/mainnet/revision/SOURCE_SHA256SUMS`; older reports/hashes describe their respective historical deliveries.
