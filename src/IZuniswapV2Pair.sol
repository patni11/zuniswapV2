// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IZuniswapV2Pair {
    function mint(address to) external returns (uint256);

    function getReserves()
        external
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimeStamp);

    function burn(
        address to
    ) external returns (uint256 tokenGiveout0, uint256 tokenGiveout1);

    function swap(uint256 amount0, uint256 amount1, address to) external;

    function initialize(address token0_, address token1_) external;

    function transferFrom(address, address, uint256) external returns (bool);
}
