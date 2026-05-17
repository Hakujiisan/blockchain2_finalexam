# GameFi Economy Protocol

A full-stack decentralized GameFi ecosystem deployed on Arbitrum Sepolia.
Built for Blockchain Technologies 2 — Final Project.

**Team:** Zhandaulet Ermekov, Alan Kissamenov, Shakarim Ainatayev

---

## Deployed Contracts (Arbitrum Sepolia)

| Contract | Address | Verified |
|---|---|---|
| GameToken (ERC-20Votes) | [0x7E7C0F7A93BCfC00c507C65d19F9ABC74398dD1d](https://sepolia.arbiscan.io/address/0x7E7C0F7A93BCfC00c507C65d19F9ABC74398dD1d#code) | ✅ |
| GameItems (ERC-1155) | [0x477BE3c4616cbcFa89aEfb73054a71a1C462EFBC](https://sepolia.arbiscan.io/address/0x477BE3c4616cbcFa89aEfb73054a71a1C462EFBC#code) | ✅ |
| ResourceAMM | [0x41ec899826C7d9619CCF06faa60af716fDF8A2C0](https://sepolia.arbiscan.io/address/0x41ec899826C7d9619CCF06faa60af716fDF8A2C0#code) | ✅ |
| ItemVault (ERC-4626) | [0x9046143CbBCb1245B1f00388cABe5547D1D64c82](https://sepolia.arbiscan.io/address/0x9046143CbBCb1245B1f00388cABe5547D1D64c82#code) | ✅ |
| LootBox | [0xd665aC62c6A10D6d69D9349Cf73857157fbA2f5E](https://sepolia.arbiscan.io/address/0xd665aC62c6A10D6d69D9349Cf73857157fbA2f5E#code) | ✅ |
| MockAggregator | [0x780F34f67F8fF3B089b037d5129588899354e20E](https://sepolia.arbiscan.io/address/0x780F34f67F8fF3B089b037d5129588899354e20E#code) | ✅ |
| MyTimelock | [0x84958013C4210f3B46E2b5832d636A725e1B9Ca0](https://sepolia.arbiscan.io/address/0x84958013C4210f3B46E2b5832d636A725e1B9Ca0#code) | ✅ |
| MyGovernor | [0x495228aA67b232Be46c3c86e8f4206D5155C8e68](https://sepolia.arbiscan.io/address/0x495228aA67b232Be46c3c86e8f4206D5155C8e68#code) | ✅ |

---

## Test Results

92 tests passing — 0 failing

---

## Setup

```bash
git clone https://github.com/Hakujiisan/blockchain2_finalexam.git
cd blockchain2_finalexam
forge install
forge build
forge test
```

## Deploy

```bash
forge script script/Deploy.s.sol \
  --rpc-url https://sepolia-rollup.arbitrum.io/rpc \
  --broadcast
```

## Frontend

```bash
python3 -m http.server 8080
# Open http://localhost:8080
# Connect MetaMask on Arbitrum Sepolia (Chain ID: 421614)
```