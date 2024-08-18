use starknet::{ContractAddress, EthAddress};

use snforge_std::{
    declare, ContractClassTrait, cheat_caller_address, CheatSpan, spy_events,
    EventSpyAssertionsTrait, Event, EventSpyTrait
};
use push_comm::{PushComm, interface::IPushCommDispatcher, interface::IPushCommDispatcherTrait};
use super::common::{USER_1, deploy_contract, CHAIN_NAME};

#[test]
fn test_verify_channel_alias() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };
    let channel_address: EthAddress = 'some address'.try_into().unwrap();

    let mut spy = spy_events();

    // user sets the alias
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    push_comm.verify_channel_alias(channel_address);

    // assert on the vent
    let events = spy.get_events();
    assert(events.events.len() == 1, 'There should be one event');

    let (from_addrs, event) = events.events.at(0);
    assert(from_addrs == @contract_address, 'Emitted from wrong address');
    assert(event.keys.at(0) == @selector!("ChannelAlias"), 'Wrong event was emitted');
}
