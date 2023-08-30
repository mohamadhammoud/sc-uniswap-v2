// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IERC3156FlashBorrower.sol";
import "../interfaces/IERC3156FlashLender.sol";

import "../UniswapV2Router.sol";

contract FlashBorrower is IERC3156FlashBorrower {
    IERC3156FlashLender lender;
    UniswapV2Router uniswapV2Router;

    IERC20 tokenA;
    IERC20 tokenB;

    constructor(
        IERC3156FlashLender lender_,
        UniswapV2Router uniswapV2Router_,
        IERC20 tokenA_,
        IERC20 tokenB_
    ) {
        lender = lender_;
        uniswapV2Router = uniswapV2Router_;

        tokenA = tokenA_;
        tokenB = tokenB_;
    }

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        require(
            msg.sender == address(lender),
            "FlashBorrower: Untrusted lender"
        );
        require(
            initiator == address(this),
            "FlashBorrower: External loan initiator"
        );

        if (token == address(tokenA)) {
            address[] memory path = new address[](2);
            path[0] = address(tokenA);
            path[1] = address(tokenB);
            tokenA.approve(address(uniswapV2Router), amount);
            uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(
                amount,
                amount / 3,
                path,
                address(this)
            );

            path[0] = address(tokenB);
            path[1] = address(tokenA);
            tokenB.approve(
                address(uniswapV2Router),
                amounts[amounts.length - 1]
            );
            uniswapV2Router.swapExactTokensForTokens(
                amounts[amounts.length - 1],
                amount / 2,
                path,
                address(this)
            );

            IERC20(token).approve(msg.sender, amount + fee);
        }

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function borrow(IERC20 token, uint256 amount) external {
        lender.flashLoan(
            IERC3156FlashBorrower(address(this)),
            address(token),
            amount,
            ""
        );
    }
}
