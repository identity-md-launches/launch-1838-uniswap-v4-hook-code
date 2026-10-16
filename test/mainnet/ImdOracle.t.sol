// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
import {ImdFixture} from "./ImdFixture.sol";
import {ImdUsdSource, IV3OraclePool} from "../../src/mainnet/ImdUsdSource.sol";
import {UnlkImdOracle} from "../../src/mainnet/UnlkImdOracle.sol";
import {MainnetPins} from "../../src/mainnet/MainnetPins.sol";

contract ImdOracleTest is ImdFixture {
    function testFullMilestoneLadderReachableAndFeeContinuesAfterPermanentBypass() public {
        uint256 out = _buy(alice, 200000 ether);
        _advance(2 hours);
        hook.updateMilestone();
        assertGe(oracle.fdvUsd(), hook.tierThreshold(15));
        for (uint8 t; t < 16; t++) {
            uint256 duration = t == 15 ? 24 hours : 6 hours;
            for (uint256 j; j < duration / 5 minutes; j++) {
                _advance(5 minutes);
                hook.updateMilestone();
            }
            assertEq(hook.tier(), t + 1);
            assertEq(hook.p(), 2500 + uint16(t) * 500);
        }
        assertTrue(hook.fullyUnlocked());
        vm.prank(alice);
        token.transfer(bob, out / 2);
        uint256 before = vault.totalAccrued();
        _sell(bob, out / 2);
        assertGt(vault.totalAccrued(), before);
        assertEq(hook.eligible(bob), 0);
        assertEq(hook.remainingQuota(bob), type(uint256).max);
        market.setOutage(true);
        assertFalse(hook.updateMilestone());
        assertEq(hook.p(), 10000);
    }

    function testUnlkTwapWarmupAndFeedOutageDoNotAdvanceOrRevoke() public {
        vm.expectRevert(UnlkImdOracle.InvalidOracle.selector);
        oracle.fdvUsd();
        _buy(alice, 10000 ether);
        _advance(2 hours);
        hook.updateMilestone();
        uint64 since = hook.qualifyingSince(0);
        assertGt(since, 0);
        uint64 last = hook.lastConfirmation();
        uint16 oldP = hook.p();
        market.setOutage(true);
        _advance(5 minutes);
        assertFalse(hook.updateMilestone());
        assertEq(hook.lastConfirmation(), last);
        assertEq(hook.qualifyingSince(0), since);
        assertEq(hook.p(), oldP);
        // Trading remains possible; only price-based progression is isolated.
        assertGt(_buy(bob, 1 ether), 0);
    }

    function testCompositeAdapterWarmupDepthFreshnessAndRealDepeg() public {
        uint256 valid = priceSource.priceUsd();
        assertGt(valid, 0);
        market.setLiquidity(1);
        vm.expectRevert(ImdUsdSource.InvalidPrice.selector);
        priceSource.priceUsd();
        market.setLiquidity(1e24);
        vm.mockCall(
            MainnetPins.ETHUSD_ADDRESS,
            abi.encodeWithSignature("latestRoundData()"),
            abi.encode(
                uint80(2), int256(3000e8), block.timestamp - 2 hours, block.timestamp - 2 hours, uint80(2)
            )
        );
        vm.expectRevert(ImdUsdSource.InvalidPrice.selector);
        priceSource.priceUsd();
        _freshFeed();
        market.setTick(70000);
        assertLt(priceSource.priceUsd(), valid, "IMD depeg lowers USD value; no peg assumption");
        ImdUsdSource fresh = new ImdUsdSource(IV3OraclePool(address(market)), address(market).codehash, 1e18);
        vm.expectRevert(ImdUsdSource.InvalidPrice.selector);
        fresh.priceUsd();
    }

    function testCrossWindowDivergenceAndHarmonicDepthFailClosed() public {
        market.setWindowTicks(60000, 30000);
        vm.expectRevert(ImdUsdSource.InvalidPrice.selector);
        priceSource.priceUsd();
        market.setWindowTicks(60000, 60000);
        market.setHistoryLiquidity(100);
        vm.expectRevert(ImdUsdSource.InvalidPrice.selector);
        priceSource.priceUsd();
    }

    function testSustainedCrossMarketManipulationRemainsEconomicRisk() public {
        uint256 honest = priceSource.priceUsd();
        // Synthetic history assumes BOTH full windows were manipulated at sufficient liquidity.
        // Agreement cannot distinguish that from a real repricing. This is an explicit release blocker,
        // not a proof of production resistance or a source of trusted USD values.
        market.setTick(0);
        uint256 manipulated = priceSource.priceUsd();
        assertGt(manipulated, honest * 100);
    }

    function testBadRoundFutureNegativeAndIncompleteRejected() public {
        for (uint8 i; i < 3; i++) {
            vm.mockCall(
                MainnetPins.ETHUSD_ADDRESS,
                abi.encodeWithSignature("latestRoundData()"),
                abi.encode(
                    uint80(2),
                    i == 0 ? int256(-1) : int256(3000e8),
                    block.timestamp,
                    i == 1 ? block.timestamp + 1 : block.timestamp,
                    i == 2 ? uint80(1) : uint80(2)
                )
            );
            vm.expectRevert(ImdUsdSource.InvalidPrice.selector);
            priceSource.priceUsd();
        }
    }
}
