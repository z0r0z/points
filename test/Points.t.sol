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
        points = new Points(alice); // Deploy.
        token = address(new TestToken(address(points), 100 ether));
    }

    // -- TESTS

    function testOwner() public {
        assertEq(points.owner(), alice);
    }

    function testCheck(uint256 score) public {
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(alicePk, toEthSignedMessageHash(keccak256(abi.encodePacked(bob, score))));
        uint256 bal = points.check(bob, score, abi.encodePacked(r, s, v));
        assertEq(bal, score);
    }

    function testClaim(uint256 score) public {
        vm.assume(score < 100 ether);
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(alicePk, toEthSignedMessageHash(keccak256(abi.encodePacked(bob, score))));
        vm.prank(bob);
        points.claim(IERC20(token), score, abi.encodePacked(r, s, v));
        assertEq(TestToken(token).balanceOf(bob), score);
    }

    function testFailDoubleClaim(uint256 score) public {
        vm.assume(score < 100 ether);
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(alicePk, toEthSignedMessageHash(keccak256(abi.encodePacked(bob, score))));
        vm.prank(bob);
        points.claim(IERC20(token), score, abi.encodePacked(r, s, v));
        assertEq(TestToken(token).balanceOf(bob), score);
        points.claim(IERC20(token), score, abi.encodePacked(r, s, v));
    }

    // -- HELPERS

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, hash) // Store into scratch space for keccak256.
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32") // 28 bytes.
            result := keccak256(0x04, 0x3c) // `32 * 2 - (32 - 28) = 60 = 0x3c`.
        }
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
