/**
 * Truffle configuration file
 * More information: https://trufflesuite.com/docs/truffle/reference/configuration
 */

const HDWalletProvider = require("@truffle/hdwallet-provider");
require("dotenv").config();

// Environment variables with fallback values
const {
  MNEMONIC,
  PROJECT_ID,
  GAS_LIMIT = "4500000",
  GAS_PRICE = "10000000000",
  MONAD_GAS_LIMIT = "30000000",
  MONAD_MAX_FEE_PER_GAS = "50000000000",
  MONAD_MAX_PRIORITY_FEE_PER_GAS = "10000000000"
} = process.env;

// Validation - only check MNEMONIC as it's required for all networks
if (!MNEMONIC) {
  console.error("❌ Please set MNEMONIC in your .env file");
  console.error("💡 Create a .env file with your 12-word mnemonic phrase:");
  console.error("   MNEMONIC=your twelve word mnemonic phrase goes here");
  process.exit(1);
}

// Only validate PROJECT_ID for Ethereum networks (not Monad)
const currentNetwork = process.argv.find(arg => arg.includes('--network'));
const isEthereumNetwork = currentNetwork && (currentNetwork.includes('sepolia') || currentNetwork.includes('mainnet'));

if (isEthereumNetwork && !PROJECT_ID) {
  console.error("❌ Please set PROJECT_ID in your .env file for Ethereum networks");
  console.error("💡 Get your Infura Project ID from https://infura.io/");
  process.exit(1);
}

module.exports = {
  networks: {
    sepolia: {
      provider: () =>
        new HDWalletProvider(
          MNEMONIC,
          `https://sepolia.infura.io/v3/${PROJECT_ID}`
        ),
      network_id: 11155111, // Sepolia's network id
      gas: parseInt(GAS_LIMIT),
      gasPrice: parseInt(GAS_PRICE), // 10 gwei
      skipDryRun: true,
      confirmations: 2,
      timeoutBlocks: 200,
    },
    monad_testnet: {
      provider: () =>
        new HDWalletProvider(MNEMONIC, `https://testnet-rpc.monad.xyz`),
      network_id: 10143,
      gas: parseInt(MONAD_GAS_LIMIT),
      maxFeePerGas: parseInt(MONAD_MAX_FEE_PER_GAS),
      maxPriorityFeePerGas: parseInt(MONAD_MAX_PRIORITY_FEE_PER_GAS),
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
    },
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
    }
  },

  mocha: {
    timeout: 100000
  },

  compilers: {
    solc: {
      version: "0.8.19",
      settings: {
        optimizer: {
          enabled: false,
          runs: 200,
        },
      },
    },
  }
};
