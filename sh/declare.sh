#!/bin/bash

# Hardcoded URLs for testnet and mainnet
TESTNET_RPC_URL="https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/DREO8_wnqH5xVktl2m9llAi7X0525BqH"
MAINNET_RPC_URL=""

DEFAULT_FEE_TOKEN="eth"

# Function to print usage information
print_usage() {
  echo "Usage: $0 [-n <network>] [-a <account>] [-k <keystore>] [-c <contract_name>] [-t <fee_token>] [-h]"
  echo ""
  echo "Arguments:"
  echo "  -n <network>             Network (testnet or mainnet, required)"
  echo "  -a <account>             Account file path (required)"
  echo "  -k <keystore>            Keystore file path (required)"
  echo "  -c <contract_name>       Contract name (required)"
  echo "  -t <fee_token>           Fee token ('eth' or 'strk', default: $DEFAULT_FEE_TOKEN)"
  echo "  -h                       Display this help message"
  exit 1
}

# Parse command-line options
while getopts ":n:a:k:c:t:h" opt; do
  case $opt in
    n) network="$OPTARG" ;;
    a) account="$OPTARG" ;;
    k) keystore="$OPTARG" ;;
    c) contract_name="$OPTARG" ;;
    t) fee_token="$OPTARG" ;;
    h) print_usage ;; # Call print_usage when -h is passed
    \?) echo "Invalid option -$OPTARG" >&2
        print_usage ;;
  esac
done

# Use default value for fee_token if not provided
fee_token=${fee_token:-$DEFAULT_FEE_TOKEN}

# Validate the fee_token value
if [[ "$fee_token" != "eth" && "$fee_token" != "strk" ]]; then
  echo "Error: fee_token (-t) must be either 'eth' or 'strk'."
  exit 1
fi

# Determine the URL based on the selected network
if [ "$network" == "testnet" ]; then
  url="$TESTNET_RPC_URL"
elif [ "$network" == "mainnet" ]; then
  url="$MAINNET_RPC_URL"
else
  echo "Error: Network (-n) must be 'testnet' or 'mainnet'."
  print_usage
fi

# Check for required arguments
if [ -z "$account" ] || [ -z "$keystore" ] || [ -z "$contract_name" ]; then
  echo "Error: account (-a), keystore (-k), and contract_name (-c) are required."
  print_usage
fi

# Declare the contract using sncast
sncast --url "$url" \
       --account "$account" \
       --keystore "$keystore" \
       declare \
       --fee-token "$fee_token" \
       --contract-name "$contract_name"
