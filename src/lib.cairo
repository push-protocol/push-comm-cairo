use starknet::ContractAddress;

#[starknet::interface]
pub trait IPushComm<TContractState> {
    // Push Admin
    fn complete_migration(ref self: TContractState);
    fn get_migration_status(self: @TContractState) -> bool;
    fn set_push_core_address(ref self: TContractState, core_address: felt252);
    fn get_push_core_address(self: @TContractState) -> felt252;
    fn get_push_governance_address(self: @TContractState) -> felt252;
    fn set_push_governance_address(ref self: TContractState, governance_address: felt252);
    fn get_push_token_address(self: @TContractState) -> felt252;
    fn set_push_token_address(ref self: TContractState, push_token_address: felt252);
    // Channel
    fn verify_channel_alias(ref self: TContractState, channel_address: felt252);
    fn add_delegate(ref self: TContractState, delegate: ContractAddress);
    fn remove_delegate(ref self: TContractState, delegate: ContractAddress);
    // User
    fn is_user_subscribed(
        self: @TContractState, channel: ContractAddress, user: ContractAddress
    ) -> bool;
    fn subscribe(ref self: TContractState, channel: ContractAddress);
    fn unsubscribe(ref self: TContractState, channel: ContractAddress);
    fn batch_subscribe(ref self: TContractState, channels: Array<ContractAddress>);
    fn batch_unsubscribe(ref self: TContractState, channels: Array<ContractAddress>);
}

#[starknet::contract]
pub mod PushComm {
    use push_comm::IPushComm;
    use core::starknet::event::EventEmitter;
    use core::starknet::storage::MutableStorageNode;
    use core::starknet::storage::StoragePointerReadAccess;
    use core::starknet::storage::StoragePathEntry;
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
        map_address_users: Map<u256, ContractAddress>,
        user_to_channel_notifs: Map<ContractAddress, Map<ContractAddress, ByteArray>>,
        // Channels
        delegatedNotificationSenders: Map<ContractAddress, Map<ContractAddress, bool>>,
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
        is_subscribed: Map<ContractAddress, bool>,
        subscribed: Map<ContractAddress, u256>,
        map_address_subscribed: Map<u256, ContractAddress>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        ChannelAlias: ChannelAlias,
        Subscribe: Subscribe,
        UnSubscribe: UnSubscribe,
        AddDelegate: AddDelegate,
        RemoveDelegate: RemoveDelegate,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ChannelAlias {
        #[key]
        pub chain_name: felt252,
        pub chain_id: felt252,
        pub channel_owner_address: ContractAddress,
        pub ethereum_channel_address: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Subscribe {
        #[key]
        pub channel: ContractAddress,
        pub user: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct UnSubscribe {
        #[key]
        pub channel: ContractAddress,
        pub user: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct AddDelegate {
        #[key]
        pub channel: ContractAddress,
        pub delegate: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct RemoveDelegate {
        #[key]
        pub channel: ContractAddress,
        pub delegate: ContractAddress,
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

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _is_user_subscribed(
            self: @ContractState, channel: ContractAddress, user: ContractAddress
        ) -> bool {
            let user_info = self.users.entry(user);
            user_info.is_subscribed.entry(channel).read()
        }

        fn _subscribe(ref self: ContractState, channel: ContractAddress, user: ContractAddress) {
            if !self._is_user_subscribed(channel, user) {
                self._add_user(user);

                let user_info = self.users.entry(user).storage_node_mut();
                let _subscribed_count = user_info.subscribed_count.read();

                // treat the count as index and update user struct
                user_info.is_subscribed.write(channel, true);
                user_info.subscribed.write(channel, _subscribed_count);
                user_info.map_address_subscribed.write(_subscribed_count, channel);
                user_info.subscribed_count.write(_subscribed_count + 1);

                // Emit
                self.emit(Subscribe { channel: channel, user: user });
            }
        }

        fn _unsubscribe(ref self: ContractState, channel: ContractAddress, user: ContractAddress) {
            if self._is_user_subscribed(channel, user) {
                let user_info = self.users.entry(user).storage_node_mut();
                let _subscribed_count = user_info.subscribed_count.read() - 1;

                // treat the count as index and update user struct
                user_info.is_subscribed.write(channel, false);

                // TODO: handle _unsubscribe core

                // Emit
                self.emit(UnSubscribe { channel: channel, user: user });
            }
        }


        fn _add_user(ref self: ContractState, user: ContractAddress) {
            let user_info = self.users.entry(user).storage_node_mut();

            if !user_info.is_activated.read() {
                user_info.is_activated.write(true);
                user_info.start_block.write(1);

                let user_count = self.users_count.read();
                self.map_address_users.write(user_count, user);
                self.users_count.write(user_count + 1);
            }
        }
    }


    #[abi(embed_v0)]
    impl PushComm of super::IPushComm<ContractState> {
        // User
        fn is_user_subscribed(
            self: @ContractState, channel: ContractAddress, user: ContractAddress
        ) -> bool {
            self._is_user_subscribed(channel, user)
        }

        fn subscribe(ref self: ContractState, channel: ContractAddress) {
            self._subscribe(channel, get_caller_address());
        }

        fn unsubscribe(ref self: ContractState, channel: ContractAddress) {
            self._unsubscribe(channel, get_caller_address());
        }

        fn batch_subscribe(ref self: ContractState, channels: Array<ContractAddress>) {
            for channel in channels {
                self._subscribe(channel, get_caller_address());
            }
        }

        fn batch_unsubscribe(ref self: ContractState, channels: Array<ContractAddress>) {
            for channel in channels {
                self._unsubscribe(channel, get_caller_address());
            }
        }


        // Admin
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

        // Channel
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

        fn add_delegate(ref self: ContractState, delegate: ContractAddress) {
            let channel = get_caller_address();
            self.delegatedNotificationSenders.entry(channel).write(delegate, true);
            self.emit(AddDelegate { channel: channel, delegate: delegate });
        }

        fn remove_delegate(ref self: ContractState, delegate: ContractAddress) {
            let channel = get_caller_address();
            self.delegatedNotificationSenders.entry(channel).write(delegate, false);
            self.emit(RemoveDelegate { channel: channel, delegate: delegate });
        }


        // Infos
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