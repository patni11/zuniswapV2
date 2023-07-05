// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "lib/forge-std/src/Test.sol";
import "./Utilities/Utils.sol";
import "forge-std/console.sol";
import "./mocks/ERC20Mintable.sol";
import "../src/libraries/ZuniSwapLibrary.sol";
import "../src/IZuniswapV2Factory.sol";
import "../src/ZuniswapV2Factory.sol";

contract ZuniswapV2LibraryTest is Test {
    ERC20Mintable tokenA;
    ERC20Mintable tokenB;
    ZuniswapV2Factory factory;
    ZuniswapV2Pair pair;

    // in setup I need token A, token B, factory address
    function setUp() public {
        tokenA = new ERC20Mintable("TOKEN A", "A");
        tokenB = new ERC20Mintable("TOKEN B", "B");
        factory = new ZuniswapV2Factory();

        address pairAddr = factory.createPair(address(tokenA), address(tokenB));

        tokenA.mint(address(this), 10 ether);
        tokenB.mint(address(this), 10 ether);

        pair = ZuniswapV2Pair(pairAddr);
    }

    function testPairFor() public {
        address pairAddress = ZuniSwapLibrary.pairFor(
            address(tokenA),
            address(tokenB),
            address(factory)
        );

        assertEq(pairAddress, factory.pairs(address(tokenA), address(tokenB)));
    }
}
