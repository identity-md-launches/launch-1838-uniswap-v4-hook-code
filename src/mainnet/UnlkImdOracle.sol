// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ImdSeedDepth as SeedDepth} from "./ImdSeedDepth.sol";
import {IUnlkHookView} from "../interfaces/IIntegration.sol";
import {MainnetPins} from "./MainnetPins.sol";

interface IImdUsdSource {
    function priceUsd() external view returns (uint256);
}

/// @notice Explicit v4 tick accumulator. No assumed built-in v4 oracle, no spot-price milestones.
contract UnlkImdOracle {
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;

    uint256 public constant WINDOW = 2 hours;
    uint256 public constant MAX_CHECKPOINT_AGE = 5 minutes;
    uint256 public constant MIN_SEED_QUOTE_CAPACITY = SeedDepth.MIN_SEED_QUOTE_CAPACITY;
    uint256 public constant SUPPLY = 1_000_000_000 ether;
    IPoolManager public immutable poolManager;
    /// @notice ETH/USD feed freshness is enforced inside the composite IMD/USD adapter.
    uint256 public constant MAX_FEED_AGE = 90 minutes;
    uint128 public constant MIN_LIQUIDITY = 1e18;
    IImdUsdSource public immutable feed;
    /// @notice The deployed stage-1 hook. Immutable: only it may bind the pool, once, at activation.
    address public immutable hook;
    address public token;
    address public factory;
    PoolId public poolId;
    bool public bound;
    bool public tokenIs0;
    uint160 public rangeLower;
    uint160 public rangeUpper;
    int24 public rangeLowerTick;
    int24 public rangeUpperTick;

    struct Observation {
        uint64 time;
        int24 tick;
        bool liquid;
        int256 tickCumulative;
        uint256 badSeconds;
    }
    Observation[] public observations;

    error Unauthorized();
    error InvalidConfig();
    error InvalidOracle();
    event Bound(PoolId indexed poolId);

    constructor(IPoolManager manager_, IImdUsdSource feed_, address hook_) {
        if (address(manager_) == address(0) || address(feed_) == address(0) || hook_ == address(0)) {
            revert InvalidConfig();
        }
        poolManager = manager_;
        feed = feed_;
        hook = hook_;
    }

    /// @notice Called once by the hook inside `configureAndActivate`, with the pool and the factory's seed range
    /// it recorded in stage 1. The pool must be IMD against the token, fee 12500, this hook.
    function bind(PoolKey calldata key, address token_, int24 lower, int24 upper) external {
        if (msg.sender != hook || bound) revert Unauthorized();
        if (
            address(key.hooks) != hook || key.fee != 12500
                || !((Currency.unwrap(key.currency0) == MainnetPins.IMD_ADDRESS
                        && Currency.unwrap(key.currency1) == token_)
                    || (Currency.unwrap(key.currency1) == MainnetPins.IMD_ADDRESS
                        && Currency.unwrap(key.currency0) == token_)) || token_ == address(0)
                || lower >= upper
        ) revert InvalidConfig();
        bound = true;
        token = token_;
        factory = IUnlkHookView(hook).launchFactory();
        tokenIs0 = Currency.unwrap(key.currency0) == token_;
        poolId = key.toId();
        rangeLower = TickMath.getSqrtPriceAtTick(lower);
        rangeUpper = TickMath.getSqrtPriceAtTick(upper);
        rangeLowerTick = lower;
        rangeUpperTick = upper;
        emit Bound(poolId);
    }

    function liquidityRangeTicks() external view returns (int24 lower, int24 upper) {
        return (rangeLowerTick, rangeUpperTick);
    }

    /// @notice Anyone may checkpoint real pool state. The hook checkpoints on both sides of state changes.
    /// @dev One observation per timestamp; replacement within a block adds ZERO price-time weight.
    function checkpoint() external {
        if (!bound) revert InvalidOracle();
        (uint160 sqrtPrice, int24 tick, uint24 protocolFee, uint24 lpFee) = poolManager.getSlot0(poolId);
        (uint128 liquidity,,) =
            poolManager.getPositionInfo(poolId, factory, rangeLowerTick, rangeUpperTick, bytes32(0));
        // Opening-value depth, with both token orders supported; no ETH reserve floor.
        uint256 depth = SeedDepth.capacity(rangeLower, rangeUpper, liquidity, tokenIs0);
        bool liquid = sqrtPrice >= rangeLower && sqrtPrice <= rangeUpper && sqrtPrice != 0
            && liquidity >= MIN_LIQUIDITY && depth >= MIN_SEED_QUOTE_CAPACITY && protocolFee == 0
            && lpFee == 12500;
        uint256 n = observations.length;
        if (n == 0) {
            observations.push(Observation(uint64(block.timestamp), tick, liquid, 0, 0));
        } else {
            Observation storage prev = observations[n - 1];
            if (prev.time == block.timestamp) {
                prev.tick = tick;
                prev.liquid = liquid;
            } else {
                (int256 cumulative, uint256 bad) = _at(prev, block.timestamp);
                observations.push(Observation(uint64(block.timestamp), tick, liquid, cumulative, bad));
            }
        }
    }

    function observationCount() external view returns (uint256) {
        return observations.length;
    }

    /// @return tick Time-weighted IMD-per-UNLK tick, rounded towards negative infinity in BOTH currency orders.
    function twapTick() public view returns (int24 tick) {
        uint256 n = observations.length;
        if (n == 0 || block.timestamp < WINDOW) revert InvalidOracle();
        Observation storage last = observations[n - 1];
        uint256 cutoff = block.timestamp - WINDOW;
        if (observations[0].time > cutoff || block.timestamp - last.time > MAX_CHECKPOINT_AGE || !last.liquid)
        {
            revert InvalidOracle();
        }
        // Find the last observation at/before the window start. O(log n), no history scan.
        uint256 lo = 0;
        uint256 hi = n;
        while (lo + 1 < hi) {
            uint256 mid = (lo + hi) / 2;
            if (observations[mid].time <= cutoff) lo = mid;
            else hi = mid;
        }
        (int256 startCumulative, uint256 startBad) = _at(observations[lo], cutoff);
        (int256 endCumulative, uint256 endBad) = _at(last, block.timestamp);
        if (endBad != startBad) revert InvalidOracle();
        int256 diff = tokenIs0 ? endCumulative - startCumulative : startCumulative - endCumulative;
        int256 mean = diff / int256(WINDOW);
        // No modulo-based pseudo-randomness: this is signed floor division, including negative ticks.
        if (mean * int256(WINDOW) > diff) --mean;
        tick = int24(mean);
    }

    /// @notice FDV is in USD with 18 decimals. Reverts on any invalid input; callers isolate failures.
    function fdvUsd() external view returns (uint256) {
        int24 tick = twapTick();
        // twapTick is already conservatively normalized to IMD per UNLK.
        uint160 sqrtPrice = TickMath.getSqrtPriceAtTick(tick);
        uint256 imdPerToken;
        if (sqrtPrice <= type(uint128).max) {
            imdPerToken = Math.mulDiv(uint256(sqrtPrice) * sqrtPrice, 1 ether, 1 << 192);
        } else {
            uint256 ratioX128 = Math.mulDiv(sqrtPrice, sqrtPrice, 1 << 64);
            imdPerToken = Math.mulDiv(ratioX128, 1 ether, 1 << 128);
        }
        uint256 imdUsd = _imdUsd();
        uint256 tokenUsd = Math.mulDiv(imdPerToken, imdUsd, 1 ether);
        return Math.mulDiv(SUPPLY, tokenUsd, 1 ether);
    }

    function _imdUsd() private view returns (uint256) {
        uint256 value = feed.priceUsd();
        if (value == 0) revert InvalidOracle();
        return value;
    }

    function _at(Observation storage observation, uint256 timestamp)
        private
        view
        returns (int256 cumulative, uint256 bad)
    {
        uint256 elapsed = timestamp - observation.time;
        cumulative = observation.tickCumulative + int256(observation.tick) * int256(elapsed);
        bad = observation.badSeconds + (observation.liquid ? 0 : elapsed);
    }
}
