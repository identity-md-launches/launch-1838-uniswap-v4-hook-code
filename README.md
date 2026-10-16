# UNLOCK / UNLK — one-way gate candidate

Implemented on top of accepted commit `3939f319d67dcd92eb50b057c0c13754ccb6b35c`. This is source, tests, candidate UI and release preparation only. No mainnet transaction, token replacement, deployment or live-site publication occurred. Existing live launch1560 configuration and contracts remain unchanged.

A valid instantaneous **official UNLK/IMD** price touch opens every crossed FDV gate immediately and permanently:20% initially,25% at$100K, then the unchanged ladder through95% at$40M. A valid$50M touch permanently bypasses quota for **all** holders, including E=0 recipients. Brief spikes and immediate selling are intended; no UNLK TWAP, confirmation timer, sequential wait or manipulation-resistance claim remains.

Cumulative acquisition/sale accounting and buy maturity are preserved. With E=1000 and S=200, the30% gate permits only100 more tokens. Gate changes never reset S or credit E. Sales are checked against the gate already open before their own post-swap update. The separate no-subscription sampled IMD/USD reference retains its48h cold start,2h/24h history, freshness and external-market checks; ongoing sampling consumes normal Ethereum gas.

**Mainnet decision: NO-GO.** The separate contributor review confirms the requested gate behavior and exact arithmetic, but **High shared-executor quota pooling** and **High external-reference manipulation** remain open. External independent audit and final published-commit release approval are pending. Fork success is not deployment safety approval.

- [Consolidated GO/NO-GO, exact checks and remaining requirements](docs/unlock-gates/HANDOFF.md)
- [Current gate/accounting/price design](docs/unlock-gates/DESIGN.md)
- [Unsigned reproducible factory/stage2 scripts and concrete release operations](docs/unlock-gates/DEPLOYMENT.md)
- [Separate contributor review, fixed findings and unresolved Highs](docs/unlock-gates/INDEPENDENT_REVIEW.md)
- [Release bytecode hashes/sizes](docs/mainnet/ARTIFACTS.json) and [ABIs](docs/mainnet/abi/)

The pinned Solidity0.8.26 project and all ordinary vendored dependencies build offline. No build configuration or dependency changed:

```sh
forge build
FOUNDRY_FUZZ_SEED=0xda8bb4c7a1dfecbe1d2824491108f08053450070bcb18434381100e02a366653 forge test
forge fmt --check
bash scripts/unlock-gates/check.sh
```

Optional read-only network evidence and local recorded-block rehearsal:

```sh
python3 scripts/unlock-gates/record-network.py https://ethereum-rpc.publicnode.com
bash scripts/unlock-gates/fork.sh https://eth.drpc.org --no-storage-caching
```

The fork deploys only into local fork state, impersonates the factory signer locally, and uses explicitly simulated future sampling/Chainlink timing; it is not actual48h oracle history. Default offline tests need no RPC, environment variables, filesystem cheatcodes or FFI.

The task prohibits `.git/` changes. The contributor uploader must publish these ordinary files while preserving history, return the exact GitHub commit and bind it to the source checksums. No unpublished SHA is invented. Earlier generations and their historical reports remain in the repository; their time-based rules and approvals do not certify this successor.
