# Uniswap V2 and ERC-3156 Integration

[![TypeScript](https://img.shields.io/badge/TypeScript-4.4.4-blue)](https://www.typescriptlang.org/)
[![Hardhat](https://img.shields.io/badge/Hardhat-2.x-orange)](https://hardhat.org/)
[![Twitter: @YourTwitterHandle](https://img.shields.io/twitter/follow/YourTwitterHandle.svg?style=social)](https://twitter.com/YourTwitterHandle)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

Welcome to the **Uniswap V2 and ERC-3156 Integration** repository! This repository contains code for integrating Uniswap V2 for decentralized token swapping and ERC-3156 for lending and borrowing functionalities.

### Uniswap V2

This implementation makes use of the following components from Uniswap V2:

- **Factory**: The Uniswap factory contract is used to create pairs of tokens for trading.
- **Router**: The router contract facilitates the actual swapping of tokens through various pairs.
- **Pair**: Pair contracts hold liquidity and enable trading between two tokens.

### ERC-3156

ERC-3156 provides a standardized interface for lending and borrowing assets. The following components are integrated:

- **FlashLender**: Implements the lending functionality allowing borrowers to temporarily borrow tokens.
- **FlashLoanBorrower**: This contract defines the actions that the borrower can take when a flash loan is executed.

Integrating Uniswap V2 and ERC-3156 offers several benefits:

- Enable decentralized token swapping with Uniswap V2.
- Implement lending and borrowing functionality through ERC-3156.
- Combine powerful features from two different standards for enhanced DeFi applications.

## Running the App

To run the Design Patterns app, follow these steps:

1. Clone the repository:

```bash
git clone https://github.com/mohamadhammoud/sc-uniswap-v2.git
cd sc-uniswap-v2

```

2.  Install the dependencies:

```
npm install
```

3.  Start the development server:

```
npx hardhat test
```

## Contributions

Contributions to this repository are welcome! If you'd like to add new patterns, improve existing ones, or provide suggestions, feel free to fork the repository and submit a pull request.

## License

This project is open source and available under the [MIT License](https://opensource.org/licenses/MIT).
