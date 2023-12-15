// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "../Points.sol";
import "../lib/forge-std/src/Test.sol";

contract PointsTest is Test {
    address alice;
    uint256 alicePk;
    address bob;
    Points points;
    address token;

    function setUp() public {
        (alice, alicePk) = makeAddrAndKey("alice");
        bob = makeAddr("bob");
        points = new Points(alice, 0); // Deploy.
        token = address(new TestToken(address(points), 100 ether));
    }

    // -- TESTS

    function testOwner() public {
        assertEq(points.owner(), alice);
    }

    function testCheck(uint256 bonus) public {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, keccak256(abi.encodePacked(bob, block.timestamp, bonus)));
        uint256 bal = points.check(bob, block.timestamp, bonus, abi.encodePacked(r, s, v));
        assertEq(bal, bonus);
    }

    function testClaim(uint256 bonus) public {
        vm.assume(bonus < 100 ether);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, keccak256(abi.encodePacked(bob, block.timestamp, bonus)));
        vm.prank(bob);
        points.claim(IERC20(token), block.timestamp, bonus, abi.encodePacked(r, s, v));
        assertEq(TestToken(token).balanceOf(bob), bonus);
    }

    function testFailDoubleClaim(uint256 bonus) public {
        vm.assume(bonus < 100 ether);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, keccak256(abi.encodePacked(bob, block.timestamp, bonus)));
        vm.prank(bob);
        points.claim(IERC20(token), block.timestamp, bonus, abi.encodePacked(r, s, v));
        assertEq(TestToken(token).balanceOf(bob), bonus);
        points.claim(IERC20(token), block.timestamp, bonus, abi.encodePacked(r, s, v));
    }
}

contract TestToken {
    event Approval(address indexed from, address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;
    uint256 totalSupply;

    constructor(address owner, uint256 supply) payable {
        totalSupply = balanceOf[owner] = supply;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        balanceOf[msg.sender] -= amount;
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address to, uint256 amount) public returns (bool) {
        balanceOf[msg.sender] -= amount;
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }
}
