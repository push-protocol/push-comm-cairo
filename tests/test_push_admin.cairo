use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, cheat_caller_address, CheatSpan, spy_events};
use push_comm::{IPushCommDispatcher, IPushCommDispatcherTrait};
use super::common::{PUSH_ADMIN, deploy_contract};

#[test]
fn test_migration_status() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };

    let migration_status = push_comm.get_migration_status();
    assert(migration_status == false, 'Initial migration set to false');

    // admin sets the migration status
    cheat_caller_address(contract_address, PUSH_ADMIN(), CheatSpan::TargetCalls(1));
    push_comm.complete_migration();

    let migration_status = push_comm.get_migration_status();
    assert(migration_status == true, 'Migration status not updated');
}


#[test]
fn test_core_contract_address() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };

    let CORE_ADDRESS: felt252 = 'some addrs';

    // admin sets the core channel address
    cheat_caller_address(contract_address, PUSH_ADMIN(), CheatSpan::TargetCalls(1));
    push_comm.set_push_core_address(CORE_ADDRESS);

    let UPDATED_ADDRESS = push_comm.get_push_core_address();
    assert(CORE_ADDRESS == UPDATED_ADDRESS, 'Core Contract Update Failed');
}


#[test]
fn test_gov_address() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };

    let GOV_ADDRESS: felt252 = 'some addrs';

    // admin sets the migration status
    cheat_caller_address(contract_address, PUSH_ADMIN(), CheatSpan::TargetCalls(1));
    push_comm.set_push_governance_address(GOV_ADDRESS);

    let UPDATED_ADDRESS = push_comm.get_push_governance_address();
    assert(GOV_ADDRESS == UPDATED_ADDRESS, 'Core Contract Update Failed');
}

#[test]
fn test_push_token_address() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };

    let TOKEN_ADDRESS: felt252 = 'some addrs';

    // admin sets the migration status
    cheat_caller_address(contract_address, PUSH_ADMIN(), CheatSpan::TargetCalls(1));
    push_comm.set_push_governance_address(TOKEN_ADDRESS);

    let UPDATED_ADDRESS = push_comm.get_push_governance_address();
    assert(TOKEN_ADDRESS == UPDATED_ADDRESS, 'Core Contract Update Failed');
}






