use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait};

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let (contract_address, _) = contract.deploy(@array![0]).unwrap();
    contract_address
}

#[test]
fn test_test() {
    let _ = deploy_contract("PushComm");
}
