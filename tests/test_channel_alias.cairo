use starknet::{ContractAddress, EthAddress};

use snforge_std::{
    declare, ContractClassTrait, cheat_caller_address, CheatSpan, spy_events,
    EventSpyAssertionsTrait, Event, EventSpyTrait
};
use push_comm::{PushComm, interface::IPushCommDispatcher, interface::IPushCommDispatcherTrait};
use super::common::{USER_1, deploy_contract, CHAIN_NAME};


#[test]
// #[ignore]
fn test_verify_channel_alias() {
    let contract_address = deploy_contract();
    let push_comm = IPushCommDispatcher { contract_address };
    let channel_address: EthAddress = 'some address'.try_into().unwrap();
    let chain_id: felt252 = 'SN_SEPOLIA'.try_into().unwrap();

    let mut spy = spy_events();

    // user sets the alias
    cheat_caller_address(contract_address, USER_1(), CheatSpan::TargetCalls(1));
    push_comm.verify_channel_alias(channel_address);

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    PushComm::Event::ChannelAlias(
                        PushComm::ChannelAlias {
                            chain_name: CHAIN_NAME(),
                            chain_id: chain_id,
                            channel_owner_address: USER_1(),
                            ethereum_channel_address: channel_address
                        }
                    )
                )
            ]
        );
}
