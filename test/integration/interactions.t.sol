//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CodeConstants} from "script/HelperConfig.s.sol";
import {CreateSubscription} from "script/interactions.s.sol";

contract InteractionTests is Test, CodeConstants, HelperConfig {
    function setUp() external {}

    function testGetConfigByChainIdHelperConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        vm.expectRevert(HelperConfig.HelperConfig__InvalidChainId.selector);
        helperConfig.getConfigByChainId(3133);
    }

    function testcreateSubscriptionUsingConfigInteractions() public {
        CreateSubscription createSubscription = new CreateSubscription();
        (uint256 subId, address vrfcooridnator) = createSubscription
            .createSubscriptionUsingConfig();
        assert(subId > 0 && vrfcooridnator != address(0));
    }
}
