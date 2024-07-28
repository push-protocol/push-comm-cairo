#[starknet::interface]
pub trait IPushComm<TContractState> {}

#[starknet::contract]
pub mod MyContract {
    use starknet::storage::Map;
    use starknet::ContractAddress;
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        user: User,
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct User {
        count: u256,
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
