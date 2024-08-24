use starknet::{ContractAddress, EthAddress};

use snforge_std::{
    declare, ContractClassTrait, cheat_caller_address, CheatSpan, spy_events,
    EventSpyAssertionsTrait, Event, EventSpyTrait
};
use push_comm::{PushComm, interface::IPushCommDispatcher, interface::IPushCommDispatcherTrait};
use super::common::{USER_1, deploy_contract, CHAIN_NAME};


#[test]
fn test_channel_delegate() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };
    let CHANNEL_ADDRESS: ContractAddress = 'some addrs'.try_into().unwrap();
    let indentity: ByteArray = "identity";
    let mut spy = spy_events();

    // Channel owner set the delegate
    cheat_caller_address(contract_address, CHANNEL_ADDRESS, CheatSpan::TargetCalls(1));
    push_comm.add_delegate(USER_1());

    // Assert AddDelegate event was emitted
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    PushComm::Event::AddDelegate(
                        PushComm::AddDelegate { channel: CHANNEL_ADDRESS, delegate: USER_1() }
                    )
                )
            ]
        );

    // Delegate can send the notification
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    let is_success = push_comm.send_notification(CHANNEL_ADDRESS, USER_1(), indentity.clone());
    assert(is_success, 'Send notification failed');

    // Channel owner remove the delegate
    cheat_caller_address(contract_address, CHANNEL_ADDRESS, CheatSpan::TargetCalls(1));
    push_comm.remove_delegate(USER_1());

    // Assert RemoveDelegate event was emitted
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    PushComm::Event::RemoveDelegate(
                        PushComm::RemoveDelegate { channel: CHANNEL_ADDRESS, delegate: USER_1() }
                    )
                )
            ]
        );


        // Removed Delegate can send the notification
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    let is_success = push_comm.send_notification(CHANNEL_ADDRESS, USER_1(), indentity.clone());
    assert(is_success == false, 'Send notification should fail');
}
