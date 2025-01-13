# Install required packages
!pip install web3 eth-tester py-solc-x python-dotenv

# Import libraries
import json
from web3 import Web3
from solcx import compile_standard, install_solc
import os

# Install specific Solidity version
install_solc("0.8.0")

# Compile Solidity code
def compile_contract(solidity_code, contract_name):
    compiled_sol = compile_standard(
        {
            "language": "Solidity",
            "sources": {f"{contract_name}.sol": {"content": solidity_code}},
            "settings": {
                "outputSelection": {
                    "*": {"*": ["abi", "metadata", "evm.bytecode", "evm.sourceMap"]}
                }
            },
        },
        solc_version="0.8.0",
    )
    return compiled_sol

# Setup local blockchain
w3 = Web3(Web3.EthereumTesterProvider())
chain_id = 1337
my_address = w3.eth.accounts[0]

# Deploy contract
def deploy_contract(compiled_sol, contract_name):
    # Get bytecode
    bytecode = compiled_sol["contracts"][f"{contract_name}.sol"][contract_name]["evm"][
        "bytecode"
    ]["object"]

    # Get ABI
    abi = compiled_sol["contracts"][f"{contract_name}.sol"][contract_name]["abi"]

    # Create contract
    Contract = w3.eth.contract(abi=abi, bytecode=bytecode)

    # Get nonce
    nonce = w3.eth.get_transaction_count(my_address)

    # Build transaction
    transaction = Contract.constructor().build_transaction(
        {
            "chainId": chain_id,
            "from": my_address,
            "nonce": nonce,
            "gasPrice": w3.eth.gas_price,
        }
    )

    # Sign transaction
    signed_txn = w3.eth.account.sign_transaction(transaction, private_key="0x" + "1" * 64)

    # Send transaction
    tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
    
    # Wait for transaction receipt
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    
    return Contract(address=tx_receipt.contractAddress)

# Example usage
solidity_code = """
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CityEmissionsContract {
    // Contract code here
}
"""

# Compile and deploy
compiled_sol = compile_contract(solidity_code, "CityEmissionsContract")
contract = deploy_contract(compiled_sol, "CityEmissionsContract")

# Test contract
print(f"Contract deployed to: {contract.address}")
