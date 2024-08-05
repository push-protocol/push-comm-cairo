#[starknet::interface]
pub trait IPushComm<TContractState> {}

#[starknet::contract]
pub mod PushComm {
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::ContractAddress;
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
        users: Map<ContractAddress,User>,
        users_count:u256,
        map_address_users:u256,
        user_to_channel_notifs:Map<ContractAddress, Map<ContractAddress, ByteArray>>,
        
        // Channels
        delegatedNotificationSenders:Map<ContractAddress, bool>,


        // Contract State
        governance: ContractAddress,
        is_migration_complete: bool,
        push_core_address:ContractAddress
    }

    #[starknet::storage_node]
    pub struct User {
        is_activated:bool,
        is_public_key_registered:bool,
        start_block:u256,
        subscribed_count:u256,
        is_subscribed: Map<ContractAddress, u8>,
        subscribed: Map<ContractAddress, u8>,
        map_address_subscribed: Map<ContractAddress, u8>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        // Set the initial owner of the contract
        self.ownable.initializer(owner);
    }


    #[abi(embed_v0)]
    impl PushComm of super::IPushComm<ContractState> {}
}
