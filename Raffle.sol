// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

/**
 * @title A sample Raffle contract
 * @author Harold
 * @notice  This contract is for creating a simple raffle
 * @dev Implements a Chainlink VRFv2.5
 */

contract Raffle {
    /** Errors */
    error Raffle__SendMoreToEnterRaffle();

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval; // @dev i_interval is the duration of the lottery in seconds
    address payable[] private s_players;
    uint256 private s_lastTimestamp;

    /** Events */
    event RaffleEntered(address indexed player);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimestamp = block.timestamp;
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!");
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());  // works for Solidity versions ^0.8.26 ,but is the most gas efficient so far

        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        // events: makes migration easier and makes frontend "indexing" easier
        emit RaffleEntered(msg.sender);
    }

    function pickWinner() external {
        // 1. Get random number
        // 2. Use the random numbe to pick a player
        // 3. Make all these processes automatic
        // Start
        // Check to see if enough time has lapsed since the last raffle
        if ((block.timestamp - s_lastTimestamp) < i_interval) {
            revert();
        }
        // If enough time has lapsed then:
        // 1. request the random number
        // 2. get the random num
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    /** Getter Functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
