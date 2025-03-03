//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfcoordinator = helperConfig.getConfig().vrfcoordinator;
        address account = helperConfig.getConfig().account;
        return createSubscription(vrfcoordinator, account);
    }

    function createSubscription(
        address vrfCoordinator,
        address account
    ) public returns (uint256, address) {
        // console.log(
        //     "Creating Subscription on chain id: ",
        //     uint256(block.chainid)
        // );
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        // console.log("Your Subscription Id is: ", uint256(subId));
        // console.log(
        //     "Please update the subscription Id in your HelperConfig.s.sol"
        // );
        return (subId, vrfCoordinator);
    }

    function run() public returns (uint256, address) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // this will convert to LINK token

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfcoordinator = helperConfig.getConfig().vrfcoordinator;
        uint256 subscriptId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;
        if (subscriptId == 0) {
            CreateSubscription createSub = new CreateSubscription();
            (uint256 updatedSubId, address updatedVrf) = createSub.run();
            subscriptId = updatedSubId;
            vrfcoordinator = updatedVrf;
            // console.log(
            //     "New SubId Created! ",
            //     uint256(subscriptId),
            //     "VRF Address: ",
            //     updatedVrf
            // );
        }
        fundSubscription(vrfcoordinator, subscriptId, linkToken, account);
    }

    function fundSubscription(
        address vrfcoordinator,
        uint256 subId,
        address linkToken,
        address account
    ) public {
        // console.log("Funding subscription: ", uint256(subId));
        // console.log("Using vrfcoordinator: ", vrfcoordinator);
        // console.log("On ChainId: ", uint256(block.chainid));
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfcoordinator).fundSubscription(
                subId,
                FUND_AMOUNT * 100
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);

            LinkToken(linkToken).transferAndCall(
                vrfcoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerUsingConfig(address mostRecentDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfcoordinator = helperConfig.getConfig().vrfcoordinator;
        uint256 subscriptId = helperConfig.getConfig().subscriptionId;
        address account = helperConfig.getConfig().account;
        addconsumer(mostRecentDeployed, vrfcoordinator, subscriptId, account);
    }

    function addconsumer(
        address contractToAddtoVrf,
        address vrfcoordinator,
        uint256 subId,
        address account
    ) public {
        // console.log("Adding Consumer contract: ", contractToAddtoVrf);
        // console.log("To Vrf Coordinator: ", vrfcoordinator);
        // console.log("On ChainId: ", uint256(block.chainid));
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfcoordinator).addConsumer(
            subId,
            contractToAddtoVrf
        );
        vm.stopBroadcast();
    }

    function run() public {
        address mostRecentDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(mostRecentDeployed);
    }
}
