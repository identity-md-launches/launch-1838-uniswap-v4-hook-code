// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
import {ImdFixture} from "./ImdFixture.sol";
import {ImdV4UsdSource} from "../../src/mainnet/ImdV4UsdSource.sol";
import {ImdUsdSource, IV3OraclePool} from "../../src/mainnet/ImdUsdSource.sol";
import {UnlkImdHook} from "../../src/mainnet/UnlkImdHook.sol";
import {UnlkImdOracle, IImdUsdSource} from "../../src/mainnet/UnlkImdOracle.sol";
import {MerkleClaimEvidence} from "../../src/MerkleClaimEvidence.sol";
import {IClaimEvidence} from "../../src/interfaces/IIntegration.sol";

contract V4ActivationTest is ImdFixture {
    function setUp() public override {
        _deploy(false);
        _launchTokenOnly(-129000);
    }

    function testInactiveV3CodeIsNoLongerAdmittedAsProductionSource() public {
        vm.prank(owner);
        vm.expectRevert(UnlkImdHook.InvalidConfig.selector);
        hook.deployPriceSource(
            type(ImdUsdSource).creationCode,
            abi.encode(IV3OraclePool(address(1)), bytes32(uint256(1)), uint128(1))
        );
        assertEq(hook.stagedPriceSource(), address(0));
    }

    function testUnprovenV4CannotActivateAndNativeClaimsRemainIndependent() public {
        vm.prank(owner);
        address source = hook.deployPriceSource(type(ImdV4UsdSource).creationCode, "");
        vm.prank(owner);
        (address e, address o,) = hook.deployCompanions(LAUNCH_NUMBER, IImdUsdSource(source), _codes());
        _certifySingle(MerkleClaimEvidence(e), 0, alice, REWARD);
        vm.prank(owner);
        vm.expectRevert(ImdV4UsdSource.InvalidPrice.selector);
        hook.configureAndActivate(IClaimEvidence(e), UnlkImdOracle(o), LAUNCH_NUMBER);
        assertFalse(hook.activated());
        assertEq(hook.p(), 2000);
        _advance(CONTRIBUTOR_LOCK);
        _claimReward();
        assertEq(token.balanceOf(alice), REWARD);
        vm.prank(alice);
        token.transfer(bob, REWARD / 2);
        assertEq(token.balanceOf(bob), REWARD / 2);
    }
}
