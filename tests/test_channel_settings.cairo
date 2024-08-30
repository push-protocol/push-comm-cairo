use starknet::{ContractAddress, EthAddress};

use snforge_std::{
    declare, ContractClassTrait, cheat_caller_address, CheatSpan, spy_events,
    EventSpyAssertionsTrait, Event, EventSpyTrait
};
use push_comm::{PushComm, interface::IPushCommDispatcher, interface::IPushCommDispatcherTrait};
use super::common::{USER_1, deploy_contract, CHAIN_NAME};

#[test]
fn test_channel_channel_user_settings() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };
    let CHANNEL_ADDRESS: ContractAddress = 'some addrs'.try_into().unwrap();
    let mut spy = spy_events();

    // user subscribes to the channel
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    push_comm.subscribe(CHANNEL_ADDRESS);

    // change_user_channel_settings
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    let notif_id = 1;
    let notif_settings: ByteArray = "notif_settings";
    push_comm.change_user_channel_settings(CHANNEL_ADDRESS, notif_id, notif_settings.clone());

    // Assert UserNotifcationSettingsAdded event was emitted
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    PushComm::Event::UserNotifcationSettingsAdded(
                        PushComm::UserNotifcationSettingsAdded {
                            channel: CHANNEL_ADDRESS, recipient: USER_1(), notif_id, notif_settings
                        }
                    )
                )
            ]
        );
}

#[test]
#[should_panic(expected: "User not subscribed to channel")]
fn test_channel_channel_unsubscribed_user_settings() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };
    let CHANNEL_ADDRESS: ContractAddress = 'some addrs'.try_into().unwrap();

    // change_user_channel_settings
    cheat_caller_address(contract_address, CHANNEL_ADDRESS, CheatSpan::TargetCalls(1));
    let notif_id = 1;
    let notif_settings: ByteArray = "notif_settings";
    push_comm.change_user_channel_settings(CHANNEL_ADDRESS, notif_id, notif_settings.clone());
}
