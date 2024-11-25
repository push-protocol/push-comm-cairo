use starknet::{ContractAddress};

use snforge_std::{cheat_caller_address, CheatSpan};
use push_comm::interface::{IPushCommDispatcher, IPushCommDispatcherTrait};
use super::common::{USER_1, PUSH_ADMIN, deploy_contract};


#[test]
fn test_admin_set_gov_address() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };

    let GOV_ADDRESS: ContractAddress = 'some addrs'.try_into().unwrap();

    // admin sets the migration status
    cheat_caller_address(contract_address, PUSH_ADMIN(), CheatSpan::TargetCalls(1));
    push_comm.set_push_governance_address(GOV_ADDRESS);

    let UPDATED_ADDRESS = push_comm.push_governance_address();
    assert(GOV_ADDRESS == UPDATED_ADDRESS, 'Core Contract Update Failed');
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_non_admin_set_gov_address() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };

    let GOV_ADDRESS: ContractAddress = 'some addrs'.try_into().unwrap();

    // admin sets the migration status
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    push_comm.set_push_governance_address(GOV_ADDRESS);
}

#[test]
fn test_admin_set_push_token_address() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };

    let TOKEN_ADDRESS: ContractAddress = 'user_1'.try_into().unwrap();

    // admin sets the migration status
    cheat_caller_address(contract_address, PUSH_ADMIN(), CheatSpan::TargetCalls(1));
    push_comm.set_push_governance_address(TOKEN_ADDRESS);

    let UPDATED_ADDRESS = push_comm.push_governance_address();
    assert(TOKEN_ADDRESS == UPDATED_ADDRESS, 'Core Contract Update Failed');
}


#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_non_admin_set_push_token_address() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };

    let TOKEN_ADDRESS: ContractAddress = 'user_1'.try_into().unwrap();

    // admin sets the migration status
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    push_comm.set_push_governance_address(TOKEN_ADDRESS);
}

#[test]
fn test_admin_set_chain_name() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };

    let chain_name: felt252 = 'starknet2'.try_into().unwrap();

    // admin sets the migration status
    cheat_caller_address(contract_address, PUSH_ADMIN(), CheatSpan::TargetCalls(1));
    push_comm.set_chain_name(chain_name);

    let updated_chain_name = push_comm.chain_name();
    assert(chain_name == updated_chain_name, 'Chain Name Update Failed');
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_non_admin_set_chain_name() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };

    let chain_name: felt252 = 'starknet2'.try_into().unwrap();

    // admin sets the migration status
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    push_comm.set_chain_name(chain_name);
}

#[test]
fn test_admin_set_identity_bytes_limit() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };

    let identity_bytes_limit: usize = 9200_usize;

    // admin sets the migration status
    cheat_caller_address(contract_address, PUSH_ADMIN(), CheatSpan::TargetCalls(1));
    push_comm.set_identity_bytes_limit(identity_bytes_limit);

    let updated_identity_bytes_limit = push_comm.identity_bytes_limit();
    assert(identity_bytes_limit == updated_identity_bytes_limit, 'Identity bytes Update Failed');
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_non_admin_set_identity_bytes_limit() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };

    let identity_bytes_limit: usize = 9200_usize;

    // admin sets the migration status
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    push_comm.set_identity_bytes_limit(identity_bytes_limit);
}