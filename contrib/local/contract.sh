#!/bin/bash
set -o errexit -o nounset -o pipefail -eu

CHAIN_BIN="persistencecore"
CHAIN_ID="persistencecore"
NODE="http://127.0.0.1:26658"
FEES="10000uxprt"
DIR="../../target/wasm32-unknown-unknown/release/"
mkdir -p $DIR

echo "-----------------------"
echo "## Add new simple ica host wasm contract"
RESP=$($CHAIN_BIN tx wasm store "$DIR/simple_ica_host.wasm"  --keyring-backend test \
  --from val1 --gas auto --fees $FEES -y --chain-id $CHAIN_ID --node $NODE -b block -o json --gas-adjustment 1.5)
echo "$RESP"
CODE_ID=$(echo "$RESP" | jq -r '.logs[0].events[1].attributes[-1].value')
echo "* Code id: $CODE_ID"

echo "-----------------------"
echo "## List code"
$CHAIN_BIN query wasm list-code --node $NODE --chain-id $CHAIN_ID -o json | jq

echo "-----------------------"
echo "## Create new contract instance"
INIT="{\"verifier\":\"$($CHAIN_BIN keys show val1 -a --keyring-backend test)\", \"beneficiary\":\"$($CHAIN_BIN keys show test1 -a --keyring-backend test)\"}"
$CHAIN_BIN tx wasm instantiate "$CODE_ID" "$INIT" --admin="$($CHAIN_BIN keys show val1 -a --keyring-backend test)" \
  --from val1 --amount "$FEES" --label "local0.1.0" --gas-adjustment 1.5 --fees "$FEES" \
  --gas "auto" -y --chain-id $CHAIN_ID --node $NODE --keyring-backend test -b block -o json | jq

CONTRACT=$($CHAIN_BIN query wasm list-contract-by-code "$CODE_ID" -o json --node $NODE | jq -r '.contracts[-1]')
echo "* Contract address: $CONTRACT"

echo "### Query all"
RESP=$($CHAIN_BIN query wasm contract-state all "$CONTRACT" -o json --node $NODE)
echo "$RESP" | jq
echo "### Query smart"
$CHAIN_BIN query wasm contract-state smart "$CONTRACT" '{"verifier":{}}' -o json --node $NODE | jq
echo "### Query raw"
KEY=$(echo "$RESP" | jq -r ".models[0].key")
$CHAIN_BIN query wasm contract-state raw "$CONTRACT" "$KEY" -o json --node $NODE | jq

echo "-----------------------"
echo "## Execute contract $CONTRACT"
MSG='{"release":{}}'
$CHAIN_BIN tx wasm execute "$CONTRACT" "$MSG" \
  --from val1 --gas-adjustment 1.5 --fees "$FEES" \
  --gas "auto" -y --chain-id $CHAIN_ID --node $NODE --keyring-backend test -b block -o json | jq

echo "-----------------------"
echo "## Set new admin"
echo "### Query old admin: $($CHAIN_BIN q wasm contract "$CONTRACT" --node $NODE -o json | jq -r '.contract_info.admin')"
echo "### Update contract"
$CHAIN_BIN tx wasm set-contract-admin "$CONTRACT" "$($CHAIN_BIN keys show test1 -a --keyring-backend test)" \
  --from val1 --keyring-backend test --node $NODE --gas-adjustment 1.5 --gas "auto" --fees "$FEES" -y --chain-id $CHAIN_ID -b block -o json | jq
echo "### Query new admin: $($CHAIN_BIN q wasm contract --node $NODE "$CONTRACT" -o json | jq -r '.contract_info.admin')"

echo "-----------------------"
echo "## Migrate contract"
echo "### Upload new code"
wget "https://github.com/CosmWasm/wasmd/raw/14688c09855ee928a12bcb7cd102a53b78e3cbfb/x/wasm/keeper/testdata/burner.wasm" -q -O $DIR/burner.wasm
RESP=$($CHAIN_BIN tx wasm store "$DIR/burner.wasm" --gas-adjustment 1.5 --fees "$FEES" \
  --from val1 --gas "auto" -y --chain-id $CHAIN_ID --node $NODE --keyring-backend test -b block -o json)

BURNER_CODE_ID=$(echo "$RESP" | jq -r '.logs[0].events[1].attributes[-1].value')
echo "### Migrate to code id: $BURNER_CODE_ID"

DEST_ACCOUNT=$($CHAIN_BIN keys show test1 -a)
$CHAIN_BIN tx wasm migrate "$CONTRACT" "$BURNER_CODE_ID" "{\"payout\": \"$DEST_ACCOUNT\"}" --from test1 \
  --chain-id $CHAIN_ID --node $NODE --gas "auto" --keyring-backend test --gas-adjustment 1.5 --fees "$FEES" -b block -y -o json | jq

echo "### Query destination account: $BURNER_CODE_ID"
$CHAIN_BIN q bank balances "$DEST_ACCOUNT" -o json --node $NODE | jq
echo "### Query contract meta data: $CONTRACT"
$CHAIN_BIN q wasm contract "$CONTRACT" -o json --node $NODE | jq

echo "### Query contract meta history: $CONTRACT"
$CHAIN_BIN q wasm contract-history "$CONTRACT" -o json --node $NODE | jq

echo "-----------------------"
echo "## Clear contract admin"
echo "### Query old admin: $($CHAIN_BIN q wasm contract "$CONTRACT" -o json --node $NODE | jq -r '.contract_info.admin')"
echo "### Update contract"
$CHAIN_BIN tx wasm clear-contract-admin "$CONTRACT" \
  --from test1 -y --chain-id $CHAIN_ID --node $NODE -b block -o json \
  --gas "auto" --gas-adjustment 1.5 --keyring-backend test --fees "$FEES" | jq
echo "### Query new admin: $($CHAIN_BIN q wasm contract "$CONTRACT" -o json --node $NODE | jq -r '.contract_info.admin')"
