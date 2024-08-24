use starknet::{ContractAddress, EthAddress};

use snforge_std::{
    declare, ContractClassTrait, cheat_caller_address, CheatSpan, spy_events,
    EventSpyAssertionsTrait, Event, EventSpyTrait
};
use push_comm::{PushComm, interface::IPushCommDispatcher, interface::IPushCommDispatcherTrait};
use super::common::{USER_1, deploy_contract, CHAIN_NAME};


#[test]
fn test_user_subscription_ops() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };
    let CHANNEL_ADDRESS: ContractAddress = 'some addrs'.try_into().unwrap();
    let mut spy = spy_events();

    // initally user is not subscribed to the channel
    let is_user_subscribed = push_comm.is_user_subscribed(CHANNEL_ADDRESS, USER_1());
    assert(is_user_subscribed == false, 'Initally user is not subscribed');

    // user subscribes to the channel
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    push_comm.subscribe(CHANNEL_ADDRESS);

    // user should be subscribed to the channel
    let is_user_subscribed = push_comm.is_user_subscribed(CHANNEL_ADDRESS, USER_1());
    assert(is_user_subscribed, 'User should be subscribed');

    // Assert Subscribe event was emitted
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    PushComm::Event::Subscribe(
                        PushComm::Subscribe { channel: CHANNEL_ADDRESS, user: USER_1(), }
                    )
                )
            ]
        );

    // user unsubscribes to the channel
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    push_comm.unsubscribe(CHANNEL_ADDRESS);

    // user should be unsubscribed to the channel
    let is_user_subscribed = push_comm.is_user_subscribed(CHANNEL_ADDRESS, USER_1());
    assert(is_user_subscribed == false, 'User should be unsubscribed');

    // Assert Unsubscribe event was emitted
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    PushComm::Event::UnSubscribe(
                        PushComm::UnSubscribe { channel: CHANNEL_ADDRESS, user: USER_1(), }
                    )
                )
            ]
        );
}

#[test]
fn test_user_batch_subscribe_ops() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };

    let CHANNEL_ADDRESS_1: ContractAddress = 'some addrs 1'.try_into().unwrap();
    let CHANNEL_ADDRESS_2: ContractAddress = 'some addrs 2'.try_into().unwrap();

    // initally user is not subscribed to the channel
    let is_user_subscribed = push_comm.is_user_subscribed(CHANNEL_ADDRESS_1, USER_1());
    assert(is_user_subscribed == false, 'Initally user is not subscribed');
    let is_user_subscribed = push_comm.is_user_subscribed(CHANNEL_ADDRESS_2, USER_1());
    assert(is_user_subscribed == false, 'Initally user is not subscribed');

    // user batch subscribes to the channel
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    push_comm.batch_subscribe(array![CHANNEL_ADDRESS_1, CHANNEL_ADDRESS_2]);

    // Assert user is subscribed
    let is_user_subscribed = push_comm.is_user_subscribed(CHANNEL_ADDRESS_1, USER_1());
    assert(is_user_subscribed, 'User should be subscribed');
    let is_user_subscribed = push_comm.is_user_subscribed(CHANNEL_ADDRESS_2, USER_1());
    assert(is_user_subscribed, 'User should be subscribed');

    // user batch subscribes to the channel
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    push_comm.batch_unsubscribe(array![CHANNEL_ADDRESS_1, CHANNEL_ADDRESS_2]);

    // Assert user is unsubscribed
    let is_user_subscribed = push_comm.is_user_subscribed(CHANNEL_ADDRESS_1, USER_1());
    assert(is_user_subscribed == false, 'User should be unsubscribed');
    let is_user_subscribed = push_comm.is_user_subscribed(CHANNEL_ADDRESS_2, USER_1());
    assert(is_user_subscribed == false, 'User should be unsubscribed');
}

