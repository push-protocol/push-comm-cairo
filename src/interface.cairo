use starknet::ContractAddress;

#[starknet::interface]
pub trait IPushComm<TContractState> {
    // Push Admin
    fn complete_migration(ref self: TContractState);
    fn get_migration_status(self: @TContractState) -> bool;
    fn set_push_core_address(ref self: TContractState, core_address: felt252);
    fn get_push_core_address(self: @TContractState) -> felt252;
    fn get_push_governance_address(self: @TContractState) -> ContractAddress;
    fn set_push_governance_address(ref self: TContractState, governance_address: ContractAddress);
    fn get_push_token_address(self: @TContractState) -> ContractAddress;
    fn set_push_token_address(ref self: TContractState, push_token_address: ContractAddress);
    // Channel
    fn verify_channel_alias(ref self: TContractState, channel_address: felt252);
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
    fn is_user_subscribed(
        self: @TContractState, channel: ContractAddress, user: ContractAddress
    ) -> bool;
    fn subscribe(ref self: TContractState, channel: ContractAddress);
    fn unsubscribe(ref self: TContractState, channel: ContractAddress);
    fn batch_subscribe(ref self: TContractState, channels: Array<ContractAddress>);
    fn batch_unsubscribe(ref self: TContractState, channels: Array<ContractAddress>);
}
