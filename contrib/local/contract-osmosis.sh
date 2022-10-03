#!/bin/bash
set -o errexit -o nounset -o pipefail -eu

CHAIN_BIN="wasmd"
CHAIN_ID="osmosisd"
NODE="http://127.0.0.1:26657"
FEES="10000uosmo"
DIR="../../target/wasm32-unknown-unknown/release"

echo "-----------------------"
echo "## Add new controller contract"
RESP=$($CHAIN_BIN tx wasm store "$DIR/simple_ica_controller.wasm"  --keyring-backend test \
  --from val1 --gas auto --fees $FEES -y --chain-id $CHAIN_ID --node $NODE -b block -o json --gas-adjustment 1.5)
echo "$RESP"
CODE_ID=$(echo "$RESP" | jq -r '.logs[0].events[1].attributes[-1].value')
#CODE_ID=7
echo "* Code id: $CODE_ID"

echo "-----------------------"
echo "## List code"
$CHAIN_BIN query wasm list-code --chain-id $CHAIN_ID --node $NODE -o json | jq

echo "-----------------------"
echo "## Create new contract instance"
INIT="{}"
$CHAIN_BIN tx wasm instantiate "$CODE_ID" "$INIT" --admin="$($CHAIN_BIN keys show val1 -a --keyring-backend test)" \
  --from val1 --label "controller" --gas-adjustment 1.5 --fees "$FEES" \
  --gas "auto" -y --chain-id $CHAIN_ID --keyring-backend test -b block -o json | jq

CONTRACT=$($CHAIN_BIN query wasm list-contract-by-code "$CODE_ID" -o json | jq -r '.contracts[-1]')
echo "* Contract address: $CONTRACT"

echo "### Query all"
RESP=$($CHAIN_BIN query wasm contract-state all "$CONTRACT" -o json)
echo "$RESP" | jq

#echo "-----------------------"
#echo "## Execute send_funds contract $CONTRACT"
#MSG='{"send_funds_to_addr":{"remote_addr":"persistence1pn45c2jdwfwrwva0cknfdlnfst28ucpurteeqt","transfer_channel_id":"channel-0"}}'
#
#$CHAIN_BIN tx wasm execute "$CONTRACT" "$MSG" \
#  --from val1 --gas-adjustment 1.5 --fees "$FEES" --amount "$FEES" \
#  --gas "auto" -y --chain-id $CHAIN_ID --keyring-backend test -b block -o json | jq

echo "## Get wasm ibc port id"
CONTRACT_IBC_PORTID=$($CHAIN_BIN q wasm contract $CONTRACT --chain-id $CHAIN_ID --node $NODE --output json | jq -r '.contract_info.ibc_port_id')
echo "* Contract IBC port id: $CONTRACT_IBC_PORTID"
