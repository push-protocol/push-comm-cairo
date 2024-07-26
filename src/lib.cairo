#[starknet::interface]
pub trait IPushComm<TContractState> {}

#[starknet::contract]
mod PushComm {
    #[storage]
    struct Storage {}
}
