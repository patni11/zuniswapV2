// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solmate/tokens/ERC20.sol";
import "./libraries/Math.sol";

interface IERC20 {
    function balanceOf(address) external returns (uint256);

    function transfer(address, uint256) external;
}

error InsufficientLiquidityMinted();

contract ZuniswapV2Pair is ERC20, Math {
    uint256 constant MINIMUM_LIQUIDITY = 1000;

    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;

    event Mint(
        address indexed liquidityProvider,
        uint256 indexed token0,
        uint256 indexed token1
    );

    constructor(
        address _token0,
        address _token1
    ) ERC20("ZuniswapV2Pair", "ZUNIV2", 18) {
        token0 = _token0;
        token1 = _token1;
    }

    function mint() public {
        // need my reserve, token reserve, use that to calculate balance added by the user
        // after this use the geometric mean formula to calculate LP tokens to be minted if adding liq for first time, else use min of the ratio of reserves to calculate the liquidity
        // send the LP tokens to the user, update the reserves

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;

        uint256 liquidity;

        if (totalSupply() == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply) / reserve0,
                (amount1 * totalSupply) / reserve1
            );
        }

        if (liquidity <= 0) revert InsufficientLiquidityMinted();

        _mint(msg.sender, liquidity);
        _update(balance0, balance1);

        emit Mint(msg.sender, amount0, amount1);
    }
}
