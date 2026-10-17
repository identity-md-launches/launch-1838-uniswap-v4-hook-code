# UNLOCK current-state price architecture

Status: source and tests only. Nothing deployed, broadcast or published. **Not release approved**: independent review of this revision is PENDING.

## What changed

```
UNLK/USD = official UNLK/IMD spot × existing IMD/ETH v4 spot × validated Chainlink ETH/USD
FDV      = 1,000,000,000 UNLK × UNLK/USD
```

- `src/mainnet/ImdSpotUsdSource.sol` (new, stateless, no constructor arguments) is the only admitted price source
  (`ImdReviewedCode.PRICE_SOURCE` = keccak of its creation code). `priceUsd()` reads, at call time:
  - canonical PoolManager `0x000000000004444c5dc75cB358380D2e3dE08A90` (chain 1, pinned codehash);
  - IMD/ETH pool `0xb07d640f…abfb3`, preimage (native ETH, IMD `0xD34a…63B7`, fee 10000, tickSpacing 200, no hooks); the preimage is tested to hash to the id; IMD is currency1, so the pool price is IMD per ETH;
  - IMD pinned codehash and `decimals() == 18` (native ETH is 18);
  - slot0 `sqrtPriceX96 != 0`, `lpFee == 10000`, in-range liquidity `!= 0`;
  - Chainlink ETH/USD `0x5f4e…8419`: pinned codehash, `decimals() == 8`, `answer > 0` and ≤ $1,000,000, `roundId != 0`, `startedAt != 0`, `startedAt ≤ updatedAt ≤ now`, `answeredInRound ≥ roundId`, age ≤ 90 minutes.
  - Result: `floor(ethUsd·1e10 · 2^192 / sqrtPriceX96²)` via exact 512-bit `ImdSpotMath` (both currency orders supported; no overflow over the whole TickMath domain; a zero floor reverts).
- `UnlkImdOracle` (unchanged logic) multiplies by the official UNLK/IMD `sqrtPriceX96` with the same exact math in either order, and keeps its seed-range/liquidity/fee validity checks for the official pool, which existed before and are not new milestones.
- Removed from the active path: `sample()`, observations, 48h warm-up, 2h/24h windows, tick-rate clamps, lag/gap rules, the 250-virtual-ETH screen and the keeper. `ImdSampledUsdSource` and its tests stay in the tree as **historical**; `deployPriceSource` rejects its code.
- Activation (`configureAndActivate`) still requires `priceUsd()` to succeed once, i.e. a valid current reference — no elapsed time or observation count.
- Rounding is always down at each step (IMD/USD to 1e-18 USD, then FDV), so rounding can delay but never advance a gate; the error is below 1e-9 USD of FDV per unit ratio.

## Accepted economics (requester decision, not a fix)

Instantaneous manipulation of **either** pool — the official UNLK/IMD pool or the external IMD/ETH pool — including same-transaction/flash manipulation, can open gates early and **permanently**, including the **$50M global bypass**. No manipulation resistance is claimed. Attack tests that demonstrate this are kept (`test/mainnet/OneWayGates.t.sol`, `test/mainnet/SpotOracle.t.sol::testManipulatedSpotMovesPriceImmediately`, `test/ManipulationEconomics.t.sol`). Previously accepted shared-executor quota pooling remains disclosed (`test/mainnet/SharedExecutorReview.t.sol`).

## Preserved

Sixteen gates 20%→100%, permanent highest-crossed tier, $50M bypass, cumulative E/S (1000 / 200 at 20% / only 100 more at 30%), one-block buy maturity, 10/87/3 allocation, 1.25% pool fee, 0.75% IMD treasury fee, beneficiary, principal protection, claims, transfers, sealed configuration, standard Universal Router compatibility, sale-before-post-swap gate ordering. Invalid reference data only withholds NEW advancement (`try oracle.fdvUsd()` in the hook); trading, transfers and native claims continue.

## Remaining defects / requirements (not covered by risk acceptance)

- Independent adversarial review of this revision: **pending**.
- Hook bytecode changed (new `PRICE_SOURCE` commitment): the hook CREATE2 salt must be re-mined against the final init code (`scripts/mine-hook.sh` / `scripts/mainnet/mine.mjs` with `docs/mainnet/ARTIFACTS.json`).
- Candidate UI source (`web/src/NextRelease.tsx`) text updated; `dist-candidate/` bundle was **not rebuilt** in this job.
- Public RPC availability and ordinary gas for deployment, trades and `checkpoint()` remain. No periodic price-recording transaction is needed.
- Chainlink staleness (>90 min) or an emptied IMD/ETH pool pauses new gate advancement until valid again.

## Deployment checklist (current)

1. Re-run `forge build`, `python3 scripts/mainnet/artifacts.py --check`, `forge test`, `forge fmt --check`.
2. Mine the hook salt for the final `UnlkImdHook` init code; stage 1 via the IMD LaunchFactory (`script/mainnet/PrepareImdLaunch.s.sol`).
3. Owner (`$owner`, setup authority) calls `deployPriceSource(type(ImdSpotUsdSource).creationCode, "")` (`PrepareImd.preparePriceSource()`).
4. Owner calls `deployCompanions(launchNumber, source, codes)`; certify claim round 0 on the evidence contract.
5. Confirm `ImdSpotUsdSource.priceUsd()` returns a value at the current block (fresh Chainlink, live IMD/ETH pool).
6. Owner calls `configureAndActivate(evidence, oracle, launchNumber)` — immediately; no warm-up or keeper.
7. No sampler/keeper operations. Anyone may call `checkpoint()` to persist a gate.

## Results recorded in this job

- `forge test` (fuzz seed `0x3cd71f9b…19ed`): see `docs/mainnet/spot-results/forge-test-summary.txt`.
- Recorded-block fork, block 26204722, actual factory/PoolManager/Universal Router/Permit2/IMD/IMD-ETH pool/Chainlink, `bash scripts/unlock-gates/fork.sh https://eth.drpc.org`: activation in the recorded block with no warp and no price mock; recorded IMD/USD 6.818840237269049093; normal trades, quota rejection, fees, irreversible gates, both token orders. Output: `docs/mainnet/spot-results/recorded-block-fork.txt`. (Gate-boundary cases inside that suite substitute reference fixtures after activation, as labelled in the file.) publicnode.com now refuses archive reads for that block; drpc was used.
