#!/bin/bash
set -o errexit -o nounset -o pipefail -eu

CHAIN_BIN="wasmd"
CHAIN_ID="osmosisd"
NODE="http://127.0.0.1:26657"
FEES="10000uosmo"
DIR="../../target/wasm32-unknown-unknown/release"

CONTRACT="wasm1nc5tatafv6eyq7llkr2gv50ff9e22mnf70qgjlv737ktmt4eswrqr5j2ht"
IBC_PORT="wasm.$CONTRACT"

#echo "-----------------------"
#echo "## Execute send_funds contract $CONTRACT"
#MSG='{"send_funds_to_addr":{"remote_addr":"persistence1pn45c2jdwfwrwva0cknfdlnfst28ucpurteeqt","transfer_channel_id":"channel-0"}}'
#$CHAIN_BIN tx wasm execute "$CONTRACT" "$MSG" \
#  --from val1 --gas-adjustment 1.5 --fees "$FEES" --amount "$FEES" \
#  --gas "auto" -y --chain-id $CHAIN_ID --keyring-backend test -b block -o json | jq

echo "-----------------------"
echo "## Execute remote custom bank send contract $CONTRACT"
MSG='{"send_msgs":{"channel_id":"channel-3","msgs":[{"bank":{"send":{"to_address":"persistence1qjtcxl86z0zua2egcsz4ncff2gzlcndzv9vm6q","amount":[{"denom":"uxprt","amount":"150000000"}]}}}]}}'
$CHAIN_BIN tx wasm execute "$CONTRACT" "$MSG" \
  --from val1 --gas-adjustment 1.5 --fees "$FEES" --amount "$FEES" \
  --gas "auto" -y --chain-id $CHAIN_ID --keyring-backend test -b block -o json | jq
