// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

contract Points {
    address public immutable owner; // Signatory.
    mapping(address => uint256) public claimed;

    constructor(address _owner) payable {
        owner = _owner;
    }

    function check(address user, uint256 score, bytes calldata signature) public view returns (uint256) {
        // Hash user's points score and parse owner's signature.
        bytes32 hash = keccak256((abi.encodePacked(user, score)));
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly ("memory-safe") {
            r := calldataload(signature.offset)
            s := calldataload(add(signature.offset, 0x20))
            v := byte(0, calldataload(add(signature.offset, 0x40)))
            mstore(0x20, hash) // Store into scratch space for keccak256.
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32")
            hash := keccak256(0x04, 0x3c) // `32 * 2 - (32 - 28) = 60 = 0x3c`.
        }
        // Try recovering signature from owner.
        if (ecrecover(hash, v, r, s) == owner) {
            return score - claimed[user];
        } else if (IERC1271(owner).isValidSignature(hash, signature) == IERC1271.isValidSignature.selector) {
            return score - claimed[user];
        } else {
            return 0; // Failed to recover.
        }
    }

    function claim(IERC20 token, uint256 score, bytes calldata signature) public payable {
        token.transfer(msg.sender, check(msg.sender, score, signature));
        unchecked {
            claimed[msg.sender] += score;
        }
    }
}

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
}

interface IERC1271 {
    function isValidSignature(bytes32, bytes calldata) external view returns (bytes4);
}
