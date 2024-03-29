pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT
import "./ZuniswapV2Pair.sol";
import "./IZuniswapV2Pair.sol";
import "./IZuniswapV2Factory.sol";
import "forge-std/console.sol";
//ERRORS
error IdenticalAddresses();
error PairExists();
error ZeroAddress();

contract ZuniswapV2Factory is IZuniswapV2Factory {
    //EVENTS
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    //VARIABLES
    mapping(address => mapping(address => address)) public pairs;
    address[] public allPairs;

    function createPair(
        address tokenA,
        address tokenB
    ) public returns (address pair) {
        if (tokenA == tokenB) revert IdenticalAddresses();

        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        if (token0 == address(0)) revert ZeroAddress();

        if (pairs[token0][token1] != address(0)) revert PairExists();

        bytes memory bytecode = type(ZuniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IZuniswapV2Pair(pair).initialize(token0, token1);

        pairs[token0][token1] = pair;
        pairs[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function getPair(
        address token0,
        address token1
    ) public view returns (address) {
        return pairs[token0][token1];
    }
}
