use starknet::{ContractAddress, EthAddress};

use snforge_std::{declare, ContractClassTrait, cheat_caller_address, CheatSpan, spy_events};
use push_comm::interface::{IPushCommDispatcher, IPushCommDispatcherTrait};
use super::common::{USER_1, PUSH_ADMIN, deploy_contract};


#[test]
fn test_admin_sets_core_contract_address() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };
    let CORE_ADDRESS: EthAddress = 'some addrs'.try_into().unwrap();

    // admin sets the core channel address
    cheat_caller_address(contract_address, PUSH_ADMIN(), CheatSpan::TargetCalls(1));
    push_comm.set_push_core_address(CORE_ADDRESS);

    let UPDATED_ADDRESS = push_comm.push_core_address();
    assert(CORE_ADDRESS == UPDATED_ADDRESS, 'Core Contract Update Failed');
}

#[test]
#[should_panic(expected: 'Caller is not the owner')]
fn test_non_admin_sets_core_contract_fail() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };
    let CORE_ADDRESS: EthAddress = 'some addrs'.try_into().unwrap();

    // non admin user sets the core channel address
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    push_comm.set_push_core_address(CORE_ADDRESS);
}


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

