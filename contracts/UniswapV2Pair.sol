// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";

contract UniswapV2Pair is ERC20, Math, ReentrancyGuard {
    using UQ112x112 for uint224;
    using SafeERC20 for IERC20;

    uint256 constant MINIMUM_LIQUIDITY = 1000;

    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    error AlreadyInitialized();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientOutputAmount();
    error InsufficientInputAmount();

    error InsufficientLiquidity();
    error TransferFailed();
    error InvalidK();

    constructor() ERC20("UniswapV2 Pair", "UNIV2") {}

    function initialize(address token0_, address token1_) public {
        if (token0 != address(0) || token1 != address(0))
            revert AlreadyInitialized();

        token0 = token0_;
        token1 = token1_;
    }

    function mint(address to) public returns (uint256 liquidity) {
        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - reserve0_;
        uint256 amount1 = balance1 - reserve1_;

        if (totalSupply() == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;

            // note address(0) reverts
            _mint(address(1), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply()) / reserve0_,
                (amount1 * totalSupply()) / reserve1_
            );
        }

        if (liquidity <= 0) revert InsufficientLiquidityMinted();

        _mint(to, liquidity);

        _update(balance0, balance1, reserve0_, reserve1_);
    }

    function burn(
        address to
    ) public returns (uint256 amount0, uint256 amount1) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf(address(this));

        uint256 totalSupply = totalSupply();

        amount0 = (liquidity * balance0) / totalSupply;
        amount1 = (liquidity * balance1) / totalSupply;

        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();

        _burn(address(this), liquidity);

        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();

        _update(balance0, balance1, reserve0_, reserve1_);
    }

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) public nonReentrant {
        if (amount0Out == 0 && amount1Out == 0)
            revert InsufficientOutputAmount();

        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();

        if (amount0Out > reserve0_ || amount1Out > reserve1_)
            revert InsufficientLiquidity();

        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);

        // Callback method
        // if (data.length > 0)
        //     UniswapV2Callee(to).UniswapV2Call(
        //         msg.sender,
        //         amount0Out,
        //         amount1Out,
        //         data
        //     );

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0In = balance0 > reserve0 - amount0Out
            ? balance0 - (reserve0 - amount0Out)
            : 0;

        uint256 amount1In = balance1 > reserve1 - amount1Out
            ? balance1 - (reserve1 - amount1Out)
            : 0;

        if (amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();

        // Adjusted = balance before swap - swap fee; fee stays in the contract
        uint256 balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
        uint256 balance1Adjusted = (balance1 * 1000) - (amount1In * 3);

        if (
            balance0Adjusted * balance1Adjusted <
            uint256(reserve0_) * uint256(reserve1_) * (1000 ** 2)
        ) revert InvalidK();

        _update(balance0, balance1, reserve0_, reserve1_);
    }

    function getReserves() public view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 reserve0_,
        uint112 reserve1_
    ) private {
        unchecked {
            uint32 timeElapsed = uint32(block.timestamp) - blockTimestampLast;

            if (timeElapsed > 0 && reserve0_ > 0 && reserve1_ > 0) {
                price0CumulativeLast +=
                    uint256(UQ112x112.encode(reserve1_).uqdiv(reserve0_)) *
                    timeElapsed;
                price1CumulativeLast +=
                    uint256(UQ112x112.encode(reserve0_).uqdiv(reserve1_)) *
                    timeElapsed;
            }
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        IERC20(token).safeTransfer(to, value);
    }
}
