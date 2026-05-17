# GameFi Economy Protocol

## Overview
A GameFi Economy built on Arbitrum Sepolia featuring ERC-1155 items, crafting, AMM, ERC-4626 vault, loot drops, and DAO governance.

## Deployed Contracts (Arbitrum Sepolia)

| Contract | Address |
|---|---|
| GameToken (ERC-20Votes) | [0x7E7C0F7A93BCfC00c507C65d19F9ABC74398dD1d](https://sepolia.arbiscan.io/address/0x7E7C0F7A93BCfC00c507C65d19F9ABC74398dD1d) |
| GameItems (ERC-1155) | [0x477BE3c4616cbcFa89aEfb73054a71a1C462EFBC](https://sepolia.arbiscan.io/address/0x477BE3c4616cbcFa89aEfb73054a71a1C462EFBC) |
| ResourceAMM | [0x41ec899826C7d9619CCF06faa60af716fDF8A2C0](https://sepolia.arbiscan.io/address/0x41ec899826C7d9619CCF06faa60af716fDF8A2C0) |
| ItemVault (ERC-4626) | [0x9046143CbBCb1245B1f00388cABe5547D1D64c82](https://sepolia.arbiscan.io/address/0x9046143CbBCb1245B1f00388cABe5547D1D64c82) |
| LootBox | [0xd665aC62c6A10D6d69D9349Cf73857157fbA2f5E](https://sepolia.arbiscan.io/address/0xd665aC62c6A10D6d69D9349Cf73857157fbA2f5E) |
| MockAggregator | [0x780F34f67F8fF3B089b037d5129588899354e20E](https://sepolia.arbiscan.io/address/0x780F34f67F8fF3B089b037d5129588899354e20E) |
| MyTimelock | [0x84958013C4210f3B46E2b5832d636A725e1B9Ca0](https://sepolia.arbiscan.io/address/0x84958013C4210f3B46E2b5832d636A725e1B9Ca0) |
| MyGovernor | [0x495228aA67b232Be46c3c86e8f4206D5155C8e68](https://sepolia.arbiscan.io/address/0x495228aA67b232Be46c3c86e8f4206D5155C8e68) |

## Setup
\`\`\`bash
git clone https://github.com/Hakujiisan/blockchain2_finalexam.git
cd blockchain2_finalexam
forge install
forge build
\`\`\`

## Run Tests
\`\`\`bash
forge test -vv
\`\`\`

## Deploy
\`\`\`bash
forge script script/Deploy.s.sol --rpc-url arbitrum_sepolia --broadcast
\`\`\`

## Test Results
- 29 tests passing
- GameItems: 11 tests
- ResourceAMM: 9 tests (including fuzz)
- ItemVault: 9 tests (including fuzz)

## Architecture
- **GameToken**: ERC-20Votes + ERC-20Permit governance token
- **GameItems**: ERC-1155 multi-token with crafting mechanic
- **ResourceAMM**: Constant-product AMM (x*y=k) with 0.3% fee
- **ItemVault**: ERC-4626 tokenized vault with yield simulation
- **LootBox**: Random item drops
- **MyGovernor + MyTimelock**: Full DAO governance with 2-day delay
