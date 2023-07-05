// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/forge-std/src/Test.sol";
import "../src/ZuniswapV2Pair.sol";
import "./mocks/ERC20Mintable.sol";
import "./Utilities/Utils.sol";
import "forge-std/console.sol";

contract ZuniswapV2PairTest is Test {
    ERC20Mintable token0;
    ERC20Mintable token1;
    ZuniswapV2Pair pair;
    TestUser user;

    function setUp() public {
        user = new TestUser();
        token0 = new ERC20Mintable("Token A", "TKNA");
        token1 = new ERC20Mintable("Token B", "TKNB");
        pair = new ZuniswapV2Pair(address(token0), address(token1));

        token0.mint(address(this), 10 ether);
        token1.mint(address(this), 10 ether);

        token0.mint(address(user), 10 ether);
        token1.mint(address(user), 10 ether);
    }

    function assertReserves(uint256 res1, uint256 res2) internal {
        (uint112 reserve1, uint112 reserve2, ) = pair.getReserves();
        assertEq(reserve1, res1);
        assertEq(reserve2, res2);
    }

    function testMintBootstrap() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));

        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);
        assertEq(pair.totalSupply(), 1 ether);
    }

    function testWhenTheresLiquidity() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 2 ether);

        pair.mint(address(this));

        assertEq(pair.balanceOf(address(this)), 3 ether - 1000);
        assertReserves(3 ether, 3 ether);
        assertEq(pair.totalSupply(), 3 ether);
    }

    function testUnballancedLiquidity() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));
        assertEq(pair.balanceOf(address(this)), 2 ether - 1000);
        assertReserves(3 ether, 2 ether);
    }

    function testBurn() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);

        pair.burn();
        assertEq(pair.balanceOf(address(this)), 0 ether);
        assertReserves(1000, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(token0.balanceOf(address(this)), 10 ether - 1000);
        assertEq(token1.balanceOf(address(this)), 10 ether - 1000);
    }

    function testBurnAfterUnballanced() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));
        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(address(this));

        pair.burn();

        assertEq(pair.balanceOf(address(this)), 0);
        assertReserves(1500, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(token0.balanceOf(address(this)), 10 ether - 1500);
        assertEq(token1.balanceOf(address(this)), 10 ether - 1000);
    }

    function testBurnUnballancedOtherUser() public {
        user.provideLiquidity(
            address(pair),
            address(token0),
            address(token1),
            1 ether,
            1 ether
        );

        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.balanceOf(address(user)), 1 ether - 1000);
        assertEq(pair.totalSupply(), 1 ether);

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint(address(this));
        pair.burn();

        assertEq(pair.balanceOf(address(this)), 0);
        assertReserves(1.5 ether, 1 ether);
        assertEq(pair.totalSupply(), 1 ether);
        assertEq(token0.balanceOf(address(this)), 10 ether - 0.5 ether);
        assertEq(token1.balanceOf(address(this)), 10 ether);

        user.withdrawLiq(address(pair));

        assertEq(pair.balanceOf(address(user)), 0);
        assertReserves(1500, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(token0.balanceOf(address(user)), 10 ether + 0.5 ether - 1500);
        assertEq(token1.balanceOf(address(user)), 10 ether - 1000);
    }

    function testSwap() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);

        pair.swap(0, 0.18 ether, address(this));

        //test the reserves
        assertReserves(1.1 ether, 1.82 ether);
        //test that user got the token they requested
        assertEq(token1.balanceOf(address(this)), 8.18 ether);
        //test they lost the token they sold
        assertEq(token0.balanceOf(address(this)), 8.9 ether);
    }

    function testSwapBiDirection() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        token0.transfer(address(pair), 0.1 ether);
        token1.transfer(address(pair), 0.2 ether);

        pair.swap(0.1 ether, 0.18 ether, address(this));

        //test the reserves
        assertReserves(1 ether, 2.02 ether);
        //test that user got the token they requested
        assertEq(token1.balanceOf(address(this)), 7.98 ether);
        //test they lost the token they sold
        assertEq(token0.balanceOf(address(this)), 9 ether);
    }
}

contract TestUser {
    function provideLiquidity(
        address to,
        address addr0,
        address addr1,
        uint256 token0,
        uint256 token1
    ) public {
        ERC20(addr0).transfer(to, token0);
        ERC20(addr1).transfer(to, token1);

        ZuniswapV2Pair(to).mint(address(this));
    }

    function swap(
        uint256 amount0,
        uint256 amount1,
        address to,
        address pair
    ) public {
        ZuniswapV2Pair(pair).swap(amount0, amount1, to);
    }

    function withdrawLiq(address pair) public {
        ZuniswapV2Pair(pair).burn();
    }
}
