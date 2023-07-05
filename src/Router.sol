// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// the contract should use factory to create more Pairs
// the contract should have swap functions
// the contract should be able to add liquidity for any pair

import "./IZuniswapV2Factory.sol";
import "./IZuniswapV2Pair.sol";
import "./libraries/ZuniSwapLibrary.sol";
error InsufficientBAmount();
error InsufficientAAmount();
error ExcessiveInputAmount();

contract Router {
    IZuniswapV2Factory immutable factory;

    constructor(address factoryAddress) {
        factory = IZuniswapV2Factory(factoryAddress);
    }

    function addLiquidity(
        address token0,
        address token1,
        uint amount0Desired,
        uint amount1Desired,
        uint minAmount0,
        uint minAmount1,
        address to
    ) public returns (uint amountA, uint amountB, uint liquidity) {
        if (factory.getPair(token0, token1) == address(0)) {
            factory.createPair(token0, token1);
        }

        (amountA, amountB) = _calculateLiquiity(
            token0,
            token1,
            amount0Desired,
            amount1Desired,
            minAmount0,
            minAmount1
        );

        address pairAddress = ZuniSwapLibrary.pairFor(
            token0,
            token1,
            address(factory)
        );
        _safeTransferFrom(token0, msg.sender, pairAddress, amountA);
        _safeTransferFrom(token1, msg.sender, pairAddress, amountB);
        liquidity = IZuniswapV2Pair(pairAddress).mint(to);
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                from,
                to,
                value
            )
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert SafeTransferFailed();
    }

    function _calculateLiquiity(
        address token0,
        address token1,
        uint amount0Desired,
        uint amount1Desired,
        uint minAmount0,
        uint minAmount1
    ) internal returns (uint amountA, uint amountB) {
        (uint256 reserveA, uint256 reserveB) = ZuniSwapLibrary.getReserves(
            token0,
            token1,
            address(factory)
        );

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amount0Desired, amount1Desired);
        } else {
            uint256 amountBOptimal = ZuniSwapLibrary.quote(
                reserveA,
                reserveB,
                amount0Desired
            );

            if (amountBOptimal <= amount1Desired) {
                if (amountBOptimal <= minAmount1) revert InsufficientBAmount();
                (amountA, amountB) = (amount0Desired, amountBOptimal);
            } else {
                uint256 amountAOptimal = ZuniSwapLibrary.quote(
                    reserveA,
                    reserveB,
                    amount1Desired
                );
                assert(amountAOptimal <= amount0Desired);

                if (amountAOptimal <= minAmount0) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amount1Desired);
            }
        }
    }

    function removeLiquidity(
        address token0,
        address token1,
        uint liquidity,
        uint minAmount0,
        uint minAmount1,
        address to
    ) public {
        address pair = ZuniSwapLibrary.pairFor(
            token0,
            token1,
            address(factory)
        );
        IZuniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity);
        (uint256 amount0, uint256 amount1) = IZuniswapV2Pair(pair).burn(
            msg.sender
        );

        if (amount0 < minAmount0) revert InsufficientAAmount();
        if (amount1 < minAmount1) revert InsufficientBAmount();
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountMin,
        address[] path,
        address to
    ) public returns (uint256[] memory amounts) {
        amounts = ZuniSwapLibrary.getAmountsOut(
            address(factory),
            amountIn,
            path
        );

        if (amounts[amounts.length - 1] < amountMin)
            revert InsufficientOutputAmount();

        _safeTransferFrom(
            path[0],
            msg.sender,
            ZuniSwapLibrary.pairFor(path[0], path[1], address(factorty)),
            amounts[0]
        );

        _swap(amounts, path, to);
    }

    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) public {
        for (int i = 0; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address tokenA, ) = ZuniSwapLibrary.sortTokens(input, output);

            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == tokenA
                ? (uint(0), amountOut)
                : (amountOut, uint(0));

            address to = i < path.length - 2
                ? ZuniSwapLibrary.pairFor(output, path[i + 2], address(factory))
                : _to;

            IZuniswapV2Pair(
                ZuniSwapLibrary.pairFor(input, output, address(factory))
            ).swap(amount0Out, amount1Out, to);
        }
    }

    // this is to allow any amount of input to be trasnacted to exact amount of tokens
    function swapTokensForExactTokens(
        uint256 amountIn,
        uint256 amountMax,
        address[] path,
        address to
    ) public {
        uint256[] amounts = ZuniSwapLibrary.getAmountsIn(
            address(factory),
            amountIn,
            path
        );

        if (amounts[amounts.length - 1] > amountMax)
            revert ExcessiveInputAmount();

        _safeTransferFrom(
            path[0],
            msg.sender,
            ZuniSwapLibrary.pairFor(path[0], path[1], address(factorty)),
            amounts[0]
        );

        _swap(amounts, path, to);
    }
}
