use starknet::{ContractAddress, EthAddress};

#[starknet::interface]
pub trait IPushComm<TContractState> {
    // Push Admin
    fn set_push_governance_address(ref self: TContractState, governance_address: ContractAddress);
    fn set_push_token_address(ref self: TContractState, push_token_address: ContractAddress);
    fn set_chain_name(ref self: TContractState, chain_name: felt252);
    fn set_identity_bytes_limit(ref self: TContractState, limit: usize);

    // Channel
    fn verify_channel_alias(ref self: TContractState, channel_address: EthAddress);
    fn add_delegate(ref self: TContractState, delegate: ContractAddress);
    fn remove_delegate(ref self: TContractState, delegate: ContractAddress);
    fn send_notification(
        ref self: TContractState,
        channel: ContractAddress,
        recipient: ContractAddress,
        identity: ByteArray
    ) -> bool;
    fn change_user_channel_settings(
        ref self: TContractState,
        channel: ContractAddress,
        notif_id: u256,
        notif_settings: ByteArray
    );

    // User
    fn subscribe(ref self: TContractState, channel: ContractAddress);
    fn unsubscribe(ref self: TContractState, channel: ContractAddress);
    fn batch_subscribe(ref self: TContractState, channels: Array<ContractAddress>);
    fn batch_unsubscribe(ref self: TContractState, channels: Array<ContractAddress>);

    // New Getter Functions
    fn is_user_subscribed(
        self: @TContractState, channel: ContractAddress, user: ContractAddress
    ) -> bool;
    fn users_count(self: @TContractState) -> u256;
    fn chain_name(self: @TContractState) -> felt252;
    fn identity_bytes_limit(self: @TContractState) -> usize;
    fn push_token_address(self: @TContractState) -> ContractAddress;
    fn push_governance_address(self: @TContractState) -> ContractAddress;
    fn user_to_channel_notifs(self: @TContractState, user: ContractAddress, channel: ContractAddress) -> ByteArray;
    fn map_address_users(self: @TContractState, index: u256) -> ContractAddress;
    fn delegated_notification_senders(self: @TContractState, channel: ContractAddress, delegate: ContractAddress) -> bool;
}
