# comm-cairo-smart-contracts

This is a Cairo implementation for the Push Comm Contract.

## Configuration

Before running the deployment or declaration scripts, ensure you have the following configuration:

1. **Create an `.env` File**

   Copy the `env.sample` file to create the `.env` file with the following command:

   ```bash
   cp .env.sample .env

Make sure to update the `.env` file with the correct RPC URLs and fee token.

2. **Account Files**

    Create an account using `starkli` and place the account file and keystore file in the accounts directory. 

## Deployment Guide
1. **Declare the Contract Class**

    First, you need to declare the contract class to upload the Cairo contract code to the blockchain. This step will provide you with a class_hash that is used in the deployment step.

    ```bash
    bash sh/declare.sh -n <network> -k <keystore> -a <account> -c <contract_name>

2. **Deploy the Contract**

    After declaring the contract class, you need to deploy the contract. Update the class_hash in ./deploy/2_deploy.sh with the value obtained from the declaration step.

    ```bash
    bash sh/deploy.sh -n <network> -a <account> -k <keystore> -c <class_hash> -d "<constructor_calldata>"
    