# Leveraged Position

LeveragedPosition is a position management contract that can allow users to create leveraged positions using Uniswap V3 pools and lending protocols like Aave V3 and Compound V3.

## Contract Overview

### Configurator

Configurator is main registry of protocol contracts. It also behaves as factory of proxy contracts and their admin.

### PositionDeployer

PositionDeployer is factory of LeveragedPosition that can allow users to deploy positions permissionlessly.

### PositionDescriptor

### LeveragedPosition

## Usage

Create `.env` file with the following content:

```text
# using Alchemy
ALCHEMY_API_KEY=YOUR_ALCHEMY_API_KEY
RPC_ETHEREUM="https://eth-mainnet.g.alchemy.com/v2/${ALCHEMY_API_KEY}"

# using Infura
INFURA_API_KEY=YOUR_INFURA_API_KEY
RPC_ETHEREUM="https://mainnet.infura.io/v3/${INFURA_API_KEY}"

ETHERSCAN_API_KEY_ETHEREUM=YOUR_ETHERSCAN_API_KEY
ETHERSCAN_URL_ETHEREUM="https://api.etherscan.io/api"
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```
