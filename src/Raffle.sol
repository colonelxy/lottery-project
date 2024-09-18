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

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle contract
 * @author Harold
 * @notice  This contract is for creating a simple raffle
 * @dev Implements a Chainlink VRFv2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    /** @dev Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 playerslength,
        uint256 s_raffleState
    );

    /** @dev Type declarations */
    enum RaffleState {
        OPEN, //0
        CALCULATING //1
    }

    /** @dev State variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint16 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval; // @dev i_interval is the duration of the lottery in seconds
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    address private s_recentWinner;
    uint256 private s_lastTimestamp;
    RaffleState private s_raffleState;

    /** @dev Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    /**
     * @dev Constructor
     * @param entranceFee The entrance fee for the raffle
     * @param interval The duration of the lottery in seconds
     * @param vrfCoordinator The VRF coordinator address
     * @param gasLane The gas lane for the VRF request
     * @param subscriptionId The subscription ID for the VRF request
     * @param callbackGasLimit The gas limit for the VRF callback
     */

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN; //or use RaffleState(0)
    }

    /**
     * @dev Enter the raffle
     * @notice This function allows a user to enter the raffle
     *`msg.value`, the amount of ETH to send (must be greater than or equal to the entrance fee)
     
     */

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!");
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle());  // works for Solidity versions ^0.8.26 ,but is the most gas efficient so far

        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen(); // @dev revert with a custom error message
        }
        s_players.push(payable(msg.sender));
        // events: makes migration easier and makes frontend "indexing" easier
        emit RaffleEntered(msg.sender);
    }

    // When should the winner be picked?
    /**
     * @dev checkUpkeep function is used check if a raffle can begin
     * @dev This function is called by the Chainlink node to check if the lottery is ready to have a winner picked.
     * The following must be true for upkeepNeed to be true:
     * 1. Enough time has passed between raffles - interval
     * 2. The lottery is open
     * 3. The contract has enough ETH
     * 4. Implicitly, your subscription has LINK
     * 5. The raffle has players
     * @notice This function picks a winner for the raffle
     * @param -ignored
     * @return upkeepNeeded - true if it's time to restart the lottery
     * @return  - ignored
     */

    function checkUpkeep(
        bytes memory /*checkdata*/
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = ((block.timestamp - s_lastTimestamp) >=
            i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, hex"");
    }

    /**
     * @dev Perform the upkeep necessary to pick a winner for the raffle
     * @notice This function is called by the Chainlink node to execute the raffle winner picking process
     * @param (performData) - Ignored parameter, not used in this function
     
     */
    function performUpkeep(bytes calldata /* performData */) external {
        // 1. Get random number
        // 2. Use the random numbe to pick a player
        // 3. Make all these processes automatic
        // Start
        // Check to see if upkeepNeeded is true
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;
        // If enough time has lapsed then:
        // 1. request the random number
        // 2. get the random num

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRaffleWinner(requestId); // this is redundant though since VRFCoordinatorV2_5MOCK also emits it.
    }

    /**
     * @dev Fulfill the random words request
     * @notice This function is called by the VRF coordinator to fulfill the random words request
     * @param (requestId) The request ID for the random words request
     * @param randomWords The random words generated by the VRF coordinator
     * usage example `fulfillRandomWords(123, [42])`
     */

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] calldata randomWords
    ) internal override {
        // Use modulo of randomwords received by number of players to get the winner index
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(s_recentWinner);
    }

    /**
     * @dev Getter function for the entrance fee
     * @notice This function returns the entrance fee for the raffle
     * @return The entrance fee
     * usage example  in other contracts and deployer, `getEntranceFee()`
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayers(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimestamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
