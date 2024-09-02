URL="https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/DREO8_wnqH5xVktl2m9llAi7X0525BqH"

# Add the Deployed class hash here
DEPLOYED_CLASS_HASH=

sncast --url "$URL" \
       --account "admin" \
       --accounts-file "accounts/profile.json" \
       deploy \
       --fee-token eth \
       --class-hash $DEPLOYED_CLASS_HASH \
       --constructor-calldata 0x03145d4a40ad09c6188cbb2024894a27c350fb6b101999d8f038efd2d6f94ead \
                             0x03145d4a40ad09c6188cbb2024894a27c350fb6b101999d8f038efd2d6f94ead \
                             0x0 \