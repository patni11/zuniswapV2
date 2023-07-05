// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IZuniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address token0,
        address token1
    ) external view returns (address);
}
