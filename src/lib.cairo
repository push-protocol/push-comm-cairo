pub mod interface;

use starknet::{ContractAddress};
pub use interface::IPushComm;


#[starknet::contract]
pub mod PushComm {
    use push_comm::IPushComm;
    use core::traits::TryInto;
    use core::serde::Serde;
    use core::box::BoxTrait;
    use core::clone::Clone;
    use core::num::traits::zero::Zero;
    use core::starknet::event::EventEmitter;
    use core::starknet::storage::MutableStorageNode;
    use core::starknet::storage::StoragePointerReadAccess;
    use core::starknet::storage::StoragePathEntry;
    use core::starknet::storage::StoragePointerWriteAccess;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::{ContractAddress, get_caller_address, EthAddress, contract_address_const};
    use starknet::{get_execution_info};
    use starknet::ClassHash;
    use openzeppelin::access::ownable::interface::OwnableABI;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);


    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        // Ownable
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        // Upgradeable
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        // Users
        users: Map<ContractAddress, User>,
        users_count: u256,
        map_address_users: Map<u256, ContractAddress>,
        user_to_channel_notifs: Map<ContractAddress, Map<ContractAddress, ByteArray>>,
        // Channels
        delegatedNotificationSenders: Map<ContractAddress, Map<ContractAddress, bool>>,
        // Contract State
        governance: ContractAddress,
        is_migration_complete: bool,
        push_core_address: EthAddress,
        push_token_address: ContractAddress,
        // Chain Info
        chain_name: felt252,
        chain_id: felt252,
    }

    #[starknet::storage_node]
    pub struct User {
        is_activated: bool,
        // TODO: optimized packing
        start_block: u64,
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
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        ChannelAlias: ChannelAlias,
        Subscribe: Subscribe,
        UnSubscribe: UnSubscribe,
        AddDelegate: AddDelegate,
        RemoveDelegate: RemoveDelegate,
        SendNotification: SendNotification,
        UserNotifcationSettingsAdded: UserNotifcationSettingsAdded
    }

    #[derive(Drop, starknet::Event)]
    pub struct ChannelAlias {
        #[key]
        pub chain_name: felt252,
        pub chain_id: felt252,
        pub channel_owner_address: ContractAddress,
        pub ethereum_channel_address: EthAddress,
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

    #[derive(Drop, starknet::Event)]
    pub struct SendNotification {
        #[key]
        pub channel: ContractAddress,
        pub recipient: ContractAddress,
        pub indentity: ByteArray,
    }

    #[derive(Drop, starknet::Event)]
    pub struct UserNotifcationSettingsAdded {
        #[key]
        pub channel: ContractAddress,
        pub recipient: ContractAddress,
        pub notif_id: u256,
        pub notif_settings: ByteArray,
    }


    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        push_governance: ContractAddress,
        chain_name: felt252
    ) {
        let chain_id = get_execution_info().unbox().tx_info.unbox().chain_id;

        self.ownable.initializer(owner);
        self.chain_id.write(chain_id);
        self.chain_name.write(chain_name);
        self.governance.write(push_governance);
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
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
                user_info
                    .subscribed
                    .write(
                        user_info.map_address_subscribed.entry(_subscribed_count).read(),
                        user_info.subscribed.entry(channel).read()
                    );
                user_info
                    .map_address_subscribed
                    .write(
                        user_info.subscribed.entry(channel).read(),
                        user_info.map_address_subscribed.entry(_subscribed_count).read(),
                    );

                // reset the last entry
                user_info.subscribed.write(channel, 0);
                user_info
                    .map_address_subscribed
                    .write(_subscribed_count, contract_address_const::<0>());
                user_info.subscribed_count.write(_subscribed_count);

                // Emit
                self.emit(UnSubscribe { channel: channel, user: user });
            }
        }


        fn _add_user(ref self: ContractState, user: ContractAddress) {
            let user_info = self.users.entry(user).storage_node_mut();

            if !user_info.is_activated.read() {
                let block_number = get_execution_info().unbox().block_info.unbox().block_number;
                user_info.is_activated.write(true);
                user_info.start_block.write(block_number);

                let user_count = self.users_count.read();
                self.map_address_users.write(user_count, user);
                self.users_count.write(user_count + 1);
            }
        }

        fn _check_notif_req(
            self: @ContractState, channel: ContractAddress, recipient: ContractAddress
        ) -> bool {
            let caller_address = get_caller_address();

            if (channel == caller_address)
                || self.delegatedNotificationSenders.entry(channel).entry(caller_address).read() {
                return true;
            }

            false
        }

        fn _send_notification(
            ref self: ContractState,
            channel: ContractAddress,
            recipient: ContractAddress,
            indentity: ByteArray
        ) -> bool {
            let success = self._check_notif_req(channel, recipient);
            if success {
                self
                    .emit(
                        SendNotification {
                            channel: channel, recipient: recipient, indentity: indentity
                        }
                    );
                return true;
            }

            false
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

        fn change_user_channel_settings(
            ref self: ContractState,
            channel: ContractAddress,
            notif_id: u256,
            notif_settings: ByteArray
        ) {
            let caller_address = get_caller_address();
            assert!(self._is_user_subscribed(channel, caller_address), "User not subscribed to channel");

            let modified_notif_settings = format!("@{}+@{}", notif_id, notif_settings);
            self
                .user_to_channel_notifs
                .entry(caller_address)
                .write(channel, modified_notif_settings);

            self
                .emit(
                    UserNotifcationSettingsAdded {
                        channel: channel,
                        recipient: caller_address,
                        notif_id: notif_id,
                        notif_settings: notif_settings
                    }
                );
        }


        // Admin
        fn set_push_core_address(ref self: ContractState, core_address: EthAddress) {
            self.ownable.assert_only_owner();
            self.push_core_address.write(core_address);
        }

        fn get_push_core_address(self: @ContractState) -> EthAddress {
            self.push_core_address.read()
        }

        // Channel
        fn verify_channel_alias(ref self: ContractState, channel_address: EthAddress) {
            self
                .emit(
                    ChannelAlias {
                        chain_name: self.chain_name.read(),
                        chain_id: self.chain_id.read(),
                        // chain_id: 1, //self.chain_id.read(),
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

        fn send_notification(
            ref self: ContractState,
            channel: ContractAddress,
            recipient: ContractAddress,
            identity: ByteArray
        ) -> bool {
            self._send_notification(channel, recipient, identity)
        }


        // Infos
        fn set_push_governance_address(
            ref self: ContractState, governance_address: ContractAddress
        ) {
            self.ownable.assert_only_owner();
            self.governance.write(governance_address);
        }

        fn get_push_governance_address(self: @ContractState) -> ContractAddress {
            self.governance.read()
        }

        fn set_push_token_address(ref self: ContractState, push_token_address: ContractAddress) {
            self.ownable.assert_only_owner();
            self.push_token_address.write(push_token_address);
        }

        fn get_push_token_address(self: @ContractState) -> ContractAddress {
            self.push_token_address.read()
        }
    }
}
