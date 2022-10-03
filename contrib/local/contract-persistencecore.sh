#!/bin/bash
set -o errexit -o nounset -o pipefail -eu

CHAIN_BIN="persistencecore"
CHAIN_ID="persistencecore"
NODE="http://127.0.0.1:26658"
FEES="10000uxprt"
DIR="../../target/wasm32-unknown-unknown/release/"
mkdir -p $DIR

echo "-----------------------"
echo "## Add cw1 contract"
RESP=$($CHAIN_BIN tx wasm store "../../tests/external/cw1_whitelist.wasm"  --keyring-backend test \
  --from val1 --gas auto --fees $FEES -y --chain-id $CHAIN_ID --node $NODE -b block -o json --gas-adjustment 1.5)
echo "$RESP"
CW1_CODE_ID=$(echo "$RESP" | jq -r '.logs[0].events[1].attributes[-1].value')
#CW1_CODE_ID=1
echo "* Code id: $CW1_CODE_ID"

echo "-----------------------"
echo "## Add new simple ica host wasm contract"
RESP=$($CHAIN_BIN tx wasm store "$DIR/simple_ica_host.wasm"  --keyring-backend test \
  --from val1 --gas auto --fees $FEES -y --chain-id $CHAIN_ID --node $NODE -b block -o json --gas-adjustment 1.5)
echo "$RESP"
CODE_ID=$(echo "$RESP" | jq -r '.logs[0].events[1].attributes[-1].value')
#CODE_ID=2
echo "* Code id: $CODE_ID"

echo "-----------------------"
echo "## List code"
$CHAIN_BIN query wasm list-code --node $NODE --chain-id $CHAIN_ID -o json | jq

echo "-----------------------"
echo "## Create new contract instance"
INIT="{\"cw1_code_id\":$CW1_CODE_ID}"
$CHAIN_BIN tx wasm instantiate "$CODE_ID" "$INIT" --admin="$($CHAIN_BIN keys show val1 -a --keyring-backend test)" \
  --from val1 --label "controller" --gas-adjustment 1.5 --fees "$FEES" \
  --gas "auto" -y --chain-id $CHAIN_ID --node $NODE --keyring-backend test -b block -o json | jq

CONTRACT=$($CHAIN_BIN query wasm list-contract-by-code --node $NODE  "$CODE_ID" -o json | jq -r '.contracts[-1]')
echo "* Contract address: $CONTRACT"

echo "## Get wasm ibc port id"
CONTRACT_IBC_PORTID=$($CHAIN_BIN q wasm contract $CONTRACT --chain-id $CHAIN_ID --node $NODE --output json | jq -r '.contract_info.ibc_port_id')
echo "* Contract IBC port id: $CONTRACT_IBC_PORTID"
