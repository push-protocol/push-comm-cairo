use starknet::ContractAddress;

#[starknet::interface]
pub trait IPushComm<TContractState> {
    // Push Admin
    fn complete_migration(ref self: TContractState);
    fn get_migration_status(self: @TContractState) -> bool;
    fn set_push_core_address(ref self: TContractState, core_address: felt252);
    fn get_push_core_address(self: @TContractState) -> felt252;
    fn verify_channel_alias(ref self: TContractState, channel_address: felt252);
    fn get_push_governance_address(self: @TContractState) -> felt252;
    fn set_push_governance_address(ref self: TContractState, governance_address: felt252);
    fn get_push_token_address(self: @TContractState) -> felt252;
    fn set_push_token_address(ref self: TContractState, push_token_address: felt252);
}

#[starknet::contract]
pub mod PushComm {
    use openzeppelin::access::ownable::interface::OwnableABI;
    use core::starknet::storage::StoragePointerWriteAccess;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::{ContractAddress, get_caller_address};
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        // Ownable
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        // Users
        users: Map<ContractAddress, User>,
        users_count: u256,
        map_address_users: u256,
        user_to_channel_notifs: Map<ContractAddress, Map<ContractAddress, ByteArray>>,
        // Channels
        delegatedNotificationSenders: Map<ContractAddress, bool>,
        // Contract State
        governance: felt252,
        is_migration_complete: bool,
        push_core_address: felt252,
        push_token_address: felt252,
        // Chain Info
        chain_name: felt252,
        chain_id: felt252,
    }

    #[starknet::storage_node]
    pub struct User {
        is_activated: bool,
        is_public_key_registered: bool,
        start_block: u256,
        subscribed_count: u256,
        is_subscribed: Map<ContractAddress, u8>,
        subscribed: Map<ContractAddress, u8>,
        map_address_subscribed: Map<ContractAddress, u8>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        ChannelAlias: ChannelAlias
    }

    #[derive(Drop, starknet::Event)]
    pub struct ChannelAlias {
        #[key]
        pub chain_name: felt252,
        pub chain_id: felt252,
        pub channel_owner_address: ContractAddress,
        pub ethereum_channel_address: felt252,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, owner: ContractAddress, chain_id: felt252, chain_name: felt252
    ) {
        // Set the initial owner of the contract
        self.ownable.initializer(owner);
        self.chain_id.write(chain_id);
        self.chain_name.write(chain_name);
    }


    #[abi(embed_v0)]
    impl PushComm of super::IPushComm<ContractState> {
        fn complete_migration(ref self: ContractState) {
            self.ownable.assert_only_owner();
            self.is_migration_complete.write(true);
        }

        fn get_migration_status(self: @ContractState) -> bool {
            self.is_migration_complete.read()
        }

        fn set_push_core_address(ref self: ContractState, core_address: felt252) {
            self.ownable.assert_only_owner();
            self.push_core_address.write(core_address);
        }

        fn get_push_core_address(self: @ContractState) -> felt252 {
            self.push_core_address.read()
        }

        fn verify_channel_alias(ref self: ContractState, channel_address: felt252) {
            self
                .emit(
                    ChannelAlias {
                        chain_name: self.chain_name.read(),
                        chain_id: self.chain_id.read(),
                        channel_owner_address: get_caller_address(),
                        ethereum_channel_address: channel_address
                    }
                );
        }

        fn set_push_governance_address(ref self: ContractState, governance_address: felt252) {
            self.ownable.assert_only_owner();
            self.governance.write(governance_address);
        }

        fn get_push_governance_address(self: @ContractState) -> felt252 {
            self.governance.read()
        }

        fn set_push_token_address(ref self: ContractState, push_token_address: felt252) {
            self.ownable.assert_only_owner();
            self.push_token_address.write(push_token_address);
        }

        fn get_push_token_address(self: @ContractState) -> felt252 {
            self.push_token_address.read()
        }
    }
}
