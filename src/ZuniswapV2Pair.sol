// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/solmate/src/tokens/ERC20.sol";
import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";
import "./IZuniswapV2Pair.sol";
import "forge-std/console.sol";

interface IERC20 {
    function balanceOf(address) external returns (uint256);

    function transfer(address, uint256) external;
}

error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error InsufficientOutputAmount();
error TransferFailed();
error InsufficientLiquidity();
error InvalidK();
error AlreadyInitialized();

contract ZuniswapV2Pair is ERC20, Math {
    uint256 constant MINIMUM_LIQUIDITY = 1000;

    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimeStampLast;

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    event Mint(
        address indexed liquidityProvider,
        uint256 indexed token0,
        uint256 indexed token1
    );

    event Burn(uint256 token0, uint256 token1, uint256 liquidity, address to);

    event Swap(address sender, uint256 token0, uint256 token1, address to);

    constructor(
        address _token0,
        address _token1
    ) ERC20("ZuniswapV2Pair", "ZUNIV2", 18) {
        token0 = _token0;
        token1 = _token1;
    }

    function mint(address to) public returns (uint256) {
        // need my reserve, token reserve, use that to calculate balance added by the user
        // after this use the geometric mean formula to calculate LP tokens to be minted if adding liq for first time, else use min of the ratio of reserves to calculate the liquidity
        // send the LP tokens to the user, update the reserves

        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;

        uint256 liquidity;

        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply) / reserve0,
                (amount1 * totalSupply) / reserve1
            );
        }

        if (liquidity <= 0) revert InsufficientLiquidityMinted();

        _mint(to, liquidity);
        _update(balance0, balance1, reserve0_, reserve1_);

        emit Mint(to, amount0, amount1);
        return liquidity;
    }

    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 reserve0_,
        uint112 reserve1_
    ) private {
        unchecked {
            uint32 timeElapsed = uint32(block.timestamp) - blockTimeStampLast;

            if (timeElapsed > 0 && reserve0_ > 0 && reserve1_ > 0) {
                price0CumulativeLast +=
                    uint256(
                        UQ112x112.uqdiv(UQ112x112.encode(reserve1_), reserve0_)
                    ) *
                    timeElapsed;

                price1CumulativeLast +=
                    uint256(
                        UQ112x112.uqdiv(UQ112x112.encode(reserve0_), reserve1_)
                    ) *
                    timeElapsed;
            }
        }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);

        blockTimeStampLast = uint32(block.timestamp);
    }

    function getReserves() public view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, 0);
    }

    function burn(
        address to
    ) public returns (uint tokenGiveout0, uint tokenGiveout1) {
        // burn the LP tokens (all the tokens users Has)
        // calculate the amount of each token they should receive
        // update the reservers, emit the event
        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint liquidity = balanceOf[address(this)];

        tokenGiveout0 = (liquidity * balance0) / totalSupply;
        tokenGiveout1 = (liquidity * balance1) / totalSupply;

        if (tokenGiveout0 <= 0 || tokenGiveout1 <= 0)
            revert InsufficientLiquidityBurned();

        _burn(address(this), liquidity);

        _safeTransfer(token0, to, tokenGiveout0);
        _safeTransfer(token1, to, tokenGiveout1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1, reserve0_, reserve1_);

        emit Burn(tokenGiveout0, tokenGiveout1, liquidity, to);
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert TransferFailed();
    }

    function swap(uint256 amount0, uint256 amount1, address to) public {
        if (amount0 == 0 && amount1 == 0) revert InsufficientOutputAmount();

        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();

        if (amount0 > reserve0_ || amount1 > reserve1_)
            revert InsufficientLiquidity();

        uint256 balance0 = IERC20(token0).balanceOf(address(this)) - amount0;
        uint256 balance1 = IERC20(token1).balanceOf(address(this)) - amount1;

        if (balance0 * balance1 < uint256(reserve0_) * uint256(reserve1_))
            revert InvalidK();

        _update(balance0, balance1, reserve0_, reserve1_);

        if (amount0 > 0) _safeTransfer(token0, to, amount0);
        if (amount1 > 0) _safeTransfer(token1, to, amount1);

        emit Swap(msg.sender, amount0, amount1, to);
    }

    function initialize(address token0_, address token1_) public {
        if (token0 != address(0) || token1 != address(0))
            revert AlreadyInitialized();

        token0 = token0_;
        token1 = token1_;
    }
}
