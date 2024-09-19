import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';

// ABI of the Raffle contract (you'll need to replace this with the actual ABI)
const contractABI = [
  {
    "type": "constructor",
    "inputs": [
      {
        "name": "entranceFee",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "interval",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "vrfCoordinator",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "gasLane",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "subscriptionId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "callbackGasLimit",
        "type": "uint32",
        "internalType": "uint32"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "acceptOwnership",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "checkUpkeep",
    "inputs": [
      {
        "name": "",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [
      {
        "name": "upkeepNeeded",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "enterRaffle",
    "inputs": [],
    "outputs": [],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "getEntranceFee",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getLastTimeStamp",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getPlayers",
    "inputs": [
      {
        "name": "indexOfPlayer",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getRaffleState",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint8",
        "internalType": "enum Raffle.RaffleState"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getRecentWinner",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "owner",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "performUpkeep",
    "inputs": [
      {
        "name": "",
        "type": "bytes",
        "internalType": "bytes"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "rawFulfillRandomWords",
    "inputs": [
      {
        "name": "requestId",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "randomWords",
        "type": "uint256[]",
        "internalType": "uint256[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "s_vrfCoordinator",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract IVRFCoordinatorV2Plus"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "setCoordinator",
    "inputs": [
      {
        "name": "_vrfCoordinator",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "transferOwnership",
    "inputs": [
      {
        "name": "to",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "event",
    "name": "CoordinatorSet",
    "inputs": [
      {
        "name": "vrfCoordinator",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "OwnershipTransferRequested",
    "inputs": [
      {
        "name": "from",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "to",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "OwnershipTransferred",
    "inputs": [
      {
        "name": "from",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "to",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RaffleEntered",
    "inputs": [
      {
        "name": "player",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "RequestedRaffleWinner",
    "inputs": [
      {
        "name": "requestId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "WinnerPicked",
    "inputs": [
      {
        "name": "winner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "error",
    "name": "OnlyCoordinatorCanFulfill",
    "inputs": [
      {
        "name": "have",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "want",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "OnlyOwnerOrCoordinator",
    "inputs": [
      {
        "name": "have",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "coordinator",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "Raffle__RaffleNotOpen",
    "inputs": []
  },
  {
    "type": "error",
    "name": "Raffle__SendMoreToEnterRaffle",
    "inputs": []
  },
  {
    "type": "error",
    "name": "Raffle__TransferFailed",
    "inputs": []
  },
  {
    "type": "error",
    "name": "Raffle__UpkeepNotNeeded",
    "inputs": [
      {
        "name": "balance",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "playerslength",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "s_raffleState",
        "type": "uint256",
        "internalType": "uint256"
      }
    ]
  },
  {
    "type": "error",
    "name": "ZeroAddress",
    "inputs": []
  }
];


const contractAddress = "0x7d6dd236df1379c7c2b110e5af834b0fde0d8cf7";

function App() {
  const [contract, setContract] = useState(null);
  const [account, setAccount] = useState('');
  const [entranceFee, setEntranceFee] = useState('');
  const [raffleState, setRaffleState] = useState('');
  const [recentWinner, setRecentWinner] = useState('');
  const [lastTimestamp, setLastTimestamp] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    const init = async () => {
      if (typeof window.ethereum !== 'undefined') {
        try {
          await window.ethereum.request({ method: 'eth_requestAccounts' });
          const provider = new ethers.BrowserProvider(window.ethereum);
          const signer = await provider.getSigner();
          const address = await signer.getAddress();
          setAccount(address);

          const contractInstance = new ethers.Contract(contractAddress, contractABI, signer);
          setContract(contractInstance);

          // Get initial contract state
          await updateContractState(contractInstance);

          // Listen for RaffleEntered events
          contractInstance.on("RaffleEntered", (player) => {
            console.log(`${player} entered the raffle!`);
            updateContractState(contractInstance);
          });

          // Listen for WinnerPicked events
          contractInstance.on("WinnerPicked", (winner) => {
            console.log(`Winner picked: ${winner}`);
            updateContractState(contractInstance);
          });

        } catch (error) {
          console.error("An error occurred:", error);
          setError(`Initialization error: ${error.message}`);
        }
      } else {
        setError('Please install MetaMask!');
      }
    };

    init();

    // Clean up event listeners
    return () => {
      if (contract) {
        contract.removeAllListeners("RaffleEntered");
        contract.removeAllListeners("WinnerPicked");
      }
    };
  }, []);

  const updateContractState = async (contractInstance) => {
    try {
      const fee = await contractInstance.getEntranceFee();
      setEntranceFee(ethers.formatEther(fee));

      const state = await contractInstance.getRaffleState();
      setRaffleState(state === 0 ? "OPEN" : "CALCULATING");

      const winner = await contractInstance.getRecentWinner();
      setRecentWinner(winner);

      const timestamp = await contractInstance.getLastTimeStamp();
      setLastTimestamp(new Date(Number(timestamp) * 1000).toLocaleString());
    } catch (error) {
      console.error("Error updating contract state:", error);
      setError(`Contract state update error: ${error.message}`);
    }
  };

  const handleEnterRaffle = async () => {
    if (contract) {
      try {
        const tx = await contract.enterRaffle({ value: ethers.parseEther(entranceFee) });
        await tx.wait();
        console.log("Entered raffle successfully!");
      } catch (error) {
        console.error("Error entering raffle:", error);
        setError(`Enter raffle error: ${error.message}`);
      }
    }
  };

  return (
    <div className="App">
      <h1>Raffle DApp</h1>
      {error && <p style={{ color: 'red' }}>Error: {error}</p>}
      <p>Connected Account: {account}</p>
      <p>Entrance Fee: {entranceFee} ETH</p>
      <p>Raffle State: {raffleState}</p>
      <p>Recent Winner: {recentWinner}</p>
      <p>Last Timestamp: {lastTimestamp}</p>
      <button onClick={handleEnterRaffle}>Enter Raffle</button>
    </div>
  );
}

export default App;