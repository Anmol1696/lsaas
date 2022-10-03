use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

use cosmwasm_std::{Coin, CosmosMsg};

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum CostumMsgEncoder {
    LiquidStake(LiquidStakeMsg),
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum LiquidStakeMsg {
    WasmLiquidStake {
        delegator_address: String,
        amount: Coin,
    },
}

// this is a helper to be able to return these as CosmosMsg easier
impl Into<CosmosMsg<CostumMsgEncoder>> for CostumMsgEncoder {
    fn into(self) -> CosmosMsg<CostumMsgEncoder> {
        CosmosMsg::Custom(self)
    }
}

// and another helper, so we can return SwapMsg::Trade{..}.into() as a CosmosMsg
impl Into<CosmosMsg<CostumMsgEncoder>> for LiquidStakeMsg {
    fn into(self) -> CosmosMsg<CostumMsgEncoder> {
        CosmosMsg::Custom(CostumMsgEncoder::LiquidStake(self))
    }
}
