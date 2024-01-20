# GHO Staking Vault - LFGHO Raclette Smart Contracts

## Overview
The `GHOStakingVault` is a key smart contract in the LFGHO Raclette project, developed for the LFGHO Hackathon. This contract, written in Solidity, implements a staking vault for the GHO token. It enables users to participate in gaming activities on the platform, with functionalities to stake tokens, join games, and receive rewards based on game performance.

## Key Features

- **Game Management:** Users can create, join, and manage games. Each game has its unique parameters like game name, total prize, number of players, and prize distribution.
- **Token Staking:** The contract allows for the staking of GHO tokens, facilitating their use in the gaming ecosystem.
- **Reward Distribution:** Winners of games can receive their rewards in R-GHO tokens, distributed according to the game's prize structure.

## Contract Structure

- `Game`: A struct representing a game with properties like ID, name, total prize, number of players, prize distribution, and participant addresses.
- `GHO`: An ERC20 token used for staking and rewards within the gaming platform.
- `superAdmin`: An address with administrative privileges over the contract, mainly for reward distribution.

## Functionalities

- `createGame`: Create a new game with specified parameters.
- `enterGame`: Allows users to enter an existing game by paying the required amount of R-GHO tokens.
- `distributeRewards`: Distributes rewards to the game participants based on their final ranking.

## Events and Errors

- **Events**: `GameCreated`, `GameStarted`, `GameFinished`, `ParticipantEnteredGame`.
- **Errors**: Custom errors like `NotEnoughFGHO`, `IncorrectId`, `NotStartedGame`, and more, providing clear feedback on transaction failures.

## Security and Modifiers

- **onlySuperAdmin**: A modifier ensuring that certain functions can only be executed by the `superAdmin`.

## Getting Started

To interact with this contract, one needs to have a solid understanding of Solidity and smart contract interactions. It's essential to be familiar with tools like Foundry or Hardhat for compiling and deploying contracts, and a service like Infura for interacting with the Ethereum network.

## Contribution and Development

Contributions to the contract are welcome. Developers interested in contributing can fork the repository, make their changes, and submit a pull request for review.

