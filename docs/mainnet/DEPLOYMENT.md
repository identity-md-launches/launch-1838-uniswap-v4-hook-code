# Supported preparation path — do not execute publicly

**CODE ONLY. No deployment, transaction submission, website publication or readiness claim is authorized.** H-01 is High/blocking, final mainnet independent review is pending, and no production-safe IMD/USD source is established. A token-only stage1 would strand trading until activation; do not broadcast stage1 without an independently reviewed executable stage2 path and resolved findings.

This package is a specification/calldata toolkit, not a new `launch.json`. The existing launch manifest and every live configuration remain unchanged. Future launch ID, number, real owner/setup authority, accepted commit, claims tree, receipts and signatures are later operator inputs, not coding prerequisites. No production dummy addresses, zero IDs, keys or source venues are filled in. Addresses used by tests are explicitly local fixtures/impersonations only.

## Rebuild and inspect offline

Use the unchanged foundry.toml (Solidity0.8.26, Cancun, optimizer200, metadata hash none). Build dependencies already exist as ordinary vendored files. No ffi or filesystem permission is enabled. From repository root:

```
forge build
python3 scripts/mainnet/artifacts.py --check
FOUNDRY_FUZZ_SEED=0xb992aebca039448ceb6aa325da16f06612255d105e125a5a7451b3928ec69e6e forge test
forge fmt --check
```

After intentional source changes and review, run `forge build`, `python3 scripts/mainnet/artifacts.py --write`, rebuild, run `--write` once more (verifier depends on token commitment), rebuild and `--check`. Do not change earlier candidates' commitments. `ARTIFACTS.json` records creation-code hashes, runtime-template hashes, immutable-reference offsets and sizes; `abi/` and `artifacts/` contain public interfaces and creation code. Runtime hashes with real constructor immutables must be computed from actual receipts; template hashes are not deployed code hashes. The export verifies unlinked code and EIP170/EIP3860 including all companions. The source uploader assigns the resulting exact commit; local `.git` writes are prohibited here. Bind the acceptance commit plus `SOURCE_SHA256SUMS` before review/admission.

## Stage1: official mainnet factory token and hook

IMD operator must re-read current policy/capabilities, service pins, IMD interface and canonical routes. This delivery recorded mainnet univ4_hook policy34, pairWith=imd, poolBps=8700, fee12500, 10/87/3 split. Default opening FDV=2500IMD; advertised custom range=250..250000IMD. Pool share override to87% is explicit. IMD/UNLK are18 decimals. Current opening token-only price must be derived and spacing-rounded conservatively, supporting either token order; no ETH denominator or20ETH minimum survives. The tests use normalized tick-129000 (~2499IMD total opening FDV) for the default cap. It is a derivation example, not a current manifest directive. Record full seed maths and actual policy selected for the launch.

Use factory `0x12c63b581d07093f6126bc02263c58f7eadaa96f`, manager `0x000000000004444c5dc75cB358380D2e3dE08A90`; verify actual code and getters rather than trusting this prose. Ask the factory to predict the *new* token from its real assigned launch number and reviewed UnlkToken creation code. Mine the factory's hook CREATE2 address offline:

```
node scripts/mainnet/mine.mjs FACTORY POOL_MANAGER ACTUAL_PREDICTED_NEW_TOKEN ACTUAL_SETUP_AUTHORITY
```

The four arguments are explicit, mandatory and nonzero; the first two must match pinned mainnet services. It emits salt, hook prediction, flags0x3fcc and init-code hash, never a transaction or key. The constructor is `(manager,newToken,factory,setupAuthority)` with the actual launch owner's address, never factory/msg.sender/tx.origin ownership. Verify the factory's prediction again. Admission must confirm full initcode sizes including arguments, linked-code absence, required hook bits, policy terms and companion availability. No public transaction is prepared until blockers are resolved.

## Stage2: source, companions, certification, sealing

1. `PrepareImd.preparePriceSource(verifiedVenue, verifiedVenueCodehash, independentlyJustifiedMinimumHarmonicLiquidity)` returns calldata for the owner to call `hook.deployPriceSource(reviewedCreationCode,args)`. The hook hashes the supplied creation body against a fixed commitment and uses CREATE2. There is **no usable production venue configuration in this delivery**; the discovered IMD/WETH v3 pool is zero-liquidity. Never substitute a test market or a spot feed.
2. Source requires24h after creation and both2h/24h venue history, sufficient current/harmonic depth, cross-window agreement and fresh verified ETH/USD. Real operations would wait for trustworthy history; the job tests this with vm.warp, never wall-clock waiting. Revalidate ongoing external trust and manipulation economics before proceeding. A failed source read blocks preparation and activation.
3. `PrepareImd.run(Config(actualHook,actualNumber,stagedSource,actualDistributor), completeRecipients, completeAmounts)` returns authority, hook, exact `deployCompanions`, predicted evidence/oracle/vault, `certifyRound`, and `activate` calldata. The preparation function performs read-only checks and no signing/broadcast. `deployCompanions` creates reviewed `MerkleClaimEvidence`, `UnlkImdOracle`, `ImdFeeVault`, `ImdSetupVerifier` using actual stage1 identities. Reconcile registry, factory position, initial allocations, locked principal, native distributor and factory getters.
4. A certificate submitter validates the complete actual round0 tree (unique recipients, exact amounts, root, funded total, native distributor domain). Execute `certifyRound` on the predicted evidence; no invented claim leaf. Any submitter can certify a correct tree. Native claims made before activation remain native and sync afterward.
5. Immutable setup authority calls `configureAndActivate(actualEvidence,actualOracle,actualNumber)`. Checks occur before writes, source must return a valid price, and the bundle seals once. Incorrect source, unauthorized caller, wrong companion creation code, wrong record/allocation, uncertified tree or feed outage reverts atomically. Restaging is permitted only before activation; after activation no configuration changes. A restaged price source invalidates an older companion's source binding.

## Postflight and eventual hosting (separate authorization required)

Operator verifies transaction success and canonicality, actual creation/runtime hashes including immutables, chain1, token name/symbol/supply/mint provenance, 10/87/3 balances, sorted pool key/ID, seed range/principal, fee split/getters, router/Quoter/Permit2, quoteToken, source observations/depth/freshness, certified claim root and activated/sealed bindings. Run small actual-route simulations for all four modes and inspect refunds, quotas and fee claims. Verify that the beneficiary alone can withdraw only IMD fee receipts/donations to itself, and factory LPfees stay separate. Verify claims independently of hook synchronization, no relock, and no candidate secrets in the build. Reconfirm all unresolved High findings are closed by independent review before any public operation.

Only after a real reviewed deployment should `web/src/mainnet.ts` receive its chain1 deployment identities and real runtime hashes. Rebuild/typecheck/unit/browser/mobile tests, recheck known shared-executor warnings and read-only mainnet NFT gallery, then get separate hosting authorization. Keep old live config intact and candidate writes disabled until then. Postflight must record exact accepted commit, receipts, verified ABIs, runtime hashes, actual source parameters, independent review and hosting content hash. This assignment performs none of those public writes.

After activation, an eventual operator should run a permissionless checkpoint/milestone keeper at4–5minute intervals, verify successful receipts and alert before10minutes between valid confirmations. A source outage must not be papered over with spot data: it stops progression; an excessive valid-sample gap restarts pending confirmation only. Earned tiers never reverse. Native distributor claims work without that keeper or synchronization. Anyone may redeem fee claims to the vault, but only the fixed beneficiary may withdraw. No operator can repair an active oracle/configuration through a setter; all such trust and failure behavior must be reviewed before any stage1 broadcast. This document schedules no real-time wait or transaction in this job.
