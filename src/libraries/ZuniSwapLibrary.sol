// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../IZuniswapV2Pair.sol";
import "../IZuniswapV2Factory.sol";
import "../ZuniswapV2Pair.sol";

error InsufficientAmount();
error InvalidPath();

library ZuniSwapLibrary {
    function getReserves(
        address tokenA,
        address tokenB,
        address factory
    ) public returns (uint112, uint112) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);

        (uint112 reserveA, uint112 reserveB, ) = IZuniswapV2Pair(
            pairFor(token0, token1, factory)
        ).getReserves();

        return tokenA == token0 ? (reserveA, reserveB) : (reserveB, reserveA);
    }

    function pairFor(
        address tokenA,
        address tokenB,
        address factory
    ) internal pure returns (address pairAddress) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pairAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            keccak256(type(ZuniswapV2Pair).creationCode)
                        )
                    )
                )
            )
        );
    }

    function quote(
        uint256 reserveA,
        uint256 reserveB,
        uint256 amountDesired
    ) public returns (uint256) {
        if (amountDesired == 0) revert InsufficientAmount();
        if (reserveA == 0 || reserveB == 0) revert InsufficientLiquidity();

        return (amountDesired * reserveB) / reserveA;
    }

    function sortTokens(
        address tokenA,
        address tokenB
    ) public pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
    }

    function getOutAmount(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public returns (uint) {
        if (amountIn == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;

        return numerator / denominator;
    }

    function getAmountsOut(
        address factory,
        uint256 amount,
        address[] path
    ) public returns (uint256[] memory amounts) {
        if (path.length < 2) revert InvalidPath();
        amounts[0] = amount;

        for (uint i = 1; i < path.length - 1; i++) {
            (uint112 reserve1, uint112 reserve2) = getReserves(
                path[i],
                path[i + 1],
                factory
            );
            amounts.push(getOutAmount(amount, reserve1, reserve2));
        }
    }

    function getAmountsIn(
        address factory,
        uint256 amount,
        address[] path
    ) public returns (uint256[] memory) {
        if (path.length < 2) revert InvalidPath();
        uint256[] memory amounts = new uint256[](path.length);
        amounts[path.length - 1] = amount;

        for (int i = path.length - 1; i > 0; i--) {
            (uint112 reserve1, uint112 reserve2) = getReserves(
                path[i],
                path[i - 1],
                factory
            );
            amounts[i - 1] = getAmountIn(reserve1, reserve2, amounts[i]);
        }
        return amounts;
    }

    function getAmountIn(
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 amountOut
    ) public returns (uint256) {
        if (amountOut == 0) revert InsufficientAmount();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;

        return (numerator / denominator) + 1;
    }
}
