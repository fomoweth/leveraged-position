# Leveraged Position

**LeveragedPosition** is a position management tool that enables users to create and manage leveraged positions effectively. It empowers users to amplify their exposure to a variety of assets while maintaining full control and flexibility over their positions.

## Contract Overview

The protocol comprises several key components:

[Configurator](https://github.com/fomoweth/leveraged-position/blob/main/src/Configurator.sol): A core registry contract that manages protocol contract addresses and their implementations, supporting the deployment and upgrading of proxies.

[PositionDeployer](https://github.com/fomoweth/leveraged-position/blob/main/src/PositionDeployer.sol): A factory contract that allows users to deploy `LeveragedPosition` contracts permissionlessly, facilitating the creation of new leveraged positions.

[PositionDescriptor](https://github.com/fomoweth/leveraged-position/blob/main/src/PositionDescriptor.sol): A utility contract that generates human-readable descriptions and tickers for `LeveragedPosition` contracts, providing clear insights into the underlying assets and protocols associated with a position.

[LeveragedPosition](https://github.com/fomoweth/leveraged-position/blob/main/src/LeveragedPosition.sol): The main contract that enables users to create and manage leveraged positions in a decentralized and modular way, integrating with `Uniswap V3` for swaps and lending protocols like `Aave V3` and `Compound V3` for borrowing and collateral management.

By leveraging these components, users can engage in leveraged trading, yield strategies, and risk hedging, all within a secure and modular framework that interacts seamlessly with leading DeFi protocols.

For more detailed information, you can read the full article at [Introducing LeveragedPosition](https://rkim.xyz/blog/introducing-leveraged-position).

## Use Cases

- **Leveraged Trading**: Create positions with leverage for amplified exposure to asset price movements.
- **Yield Strategies**: Manage liquidity and debt positions to optimize yield farming rewards.
- **Risk Hedging**: Hedge risks effectively while maintaining proper collateralization.

## Usage

Create `.env` file with the following content:

```text
# using Alchemy

ALCHEMY_API_KEY=YOUR_ALCHEMY_API_KEY
RPC_ETHEREUM="https://eth-mainnet.g.alchemy.com/v2/${ALCHEMY_API_KEY}"

# using Infura

INFURA_API_KEY=YOUR_INFURA_API_KEY
RPC_ETHEREUM="https://mainnet.infura.io/v3/${INFURA_API_KEY}"

# etherscan

ETHERSCAN_API_KEY_ETHEREUM=YOUR_ETHERSCAN_API_KEY
ETHERSCAN_URL_ETHEREUM="https://api.etherscan.io/api"
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test --chain 1
```
