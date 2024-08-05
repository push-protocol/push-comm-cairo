use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, cheat_caller_address, CheatSpan};

// Constants
pub fn PUSH_ADMIN() -> ContractAddress {
    'push_admin'.try_into().unwrap()
}

pub fn deploy_contract() -> ContractAddress {
    let contract = declare("PushComm").unwrap();
    let calldata = array![PUSH_ADMIN().into()];
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}
