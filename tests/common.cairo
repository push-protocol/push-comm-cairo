use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, cheat_caller_address, CheatSpan};

// Constants
pub fn PUSH_ADMIN() -> ContractAddress {
    'push_admin'.try_into().unwrap()
}

pub fn USER_1() -> ContractAddress {
    'user_1'.try_into().unwrap()
}

pub fn CHAIN_ID() -> felt252 {
    'Some ID'.try_into().unwrap()
}

pub fn CHAIN_NAME() -> felt252 {
    'Starknet'.try_into().unwrap()
}

pub fn deploy_contract() -> ContractAddress {
    let contract = declare("PushComm").unwrap();

    let calldata = array![PUSH_ADMIN().into(), CHAIN_NAME(), CHAIN_ID()];
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}