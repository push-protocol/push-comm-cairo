use starknet::{ContractAddress, EthAddress};

use snforge_std::{
    declare, ContractClassTrait, cheat_caller_address, CheatSpan, spy_events,
    EventSpyAssertionsTrait, Event, EventSpyTrait
};
use push_comm::{PushComm, interface::IPushCommDispatcher, interface::IPushCommDispatcherTrait};
use super::common::{USER_1, deploy_contract, CHAIN_NAME};


#[test]
fn test_channel_owner_send_notification() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };
    let CHANNEL_ADDRESS: ContractAddress = 'some addrs'.try_into().unwrap();
    let indentity: ByteArray = "identity";
    let mut spy = spy_events();

    // Channel owner can send the notification
    cheat_caller_address(contract_address, CHANNEL_ADDRESS, CheatSpan::TargetCalls(1));
    let is_success = push_comm.send_notification(CHANNEL_ADDRESS, USER_1(), indentity.clone());
    assert(is_success, 'Send notification failed');

    // Assert SendNotification event was emitted
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    PushComm::Event::SendNotification(
                        PushComm::SendNotification {
                            channel: CHANNEL_ADDRESS, recipient: USER_1(), indentity
                        }
                    )
                )
            ]
        );
}


#[test]
fn test_non_channel_owner_send_notification() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };
    let CHANNEL_ADDRESS: ContractAddress = 'some addrs'.try_into().unwrap();
    let indentity: ByteArray = "identity";

    // Channel owner can send the notification
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    let is_success = push_comm.send_notification(CHANNEL_ADDRESS, USER_1(), indentity.clone());
    assert(is_success == false, 'Send notification should fail');
}
