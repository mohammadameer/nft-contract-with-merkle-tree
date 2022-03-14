//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract JamNFT is ERC721URIStorage {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    MerkleTree merkleTree;

    constructor() ERC721("Jam", "JM") {
        merkleTree = new MerkleTree();
    }

    // used to get URI for a tokenId and to create URI for new ones
    function tokenURI(uint256 _tokenId)
        public
        pure
        override
        returns (string memory)
    {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "JamNFT #',
            _tokenId.toString(),
            '",',
            '"description": "this NFT is part of JamNFTs ",',
            "}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64, ",
                    Base64.encode(dataURI)
                )
            );
    }

    function mintNFT(address _to) public {
        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();

        string memory newTokenURI = tokenURI(newTokenId);

        _mint(_to, newTokenId);
        _setTokenURI(newTokenId, newTokenURI);

        bytes32 hash = computeHash(msg.sender, _to, newTokenId, newTokenURI);
        merkleTree.addItem(hash);
    }

    // hash sender, receiver, tokenId to be added to the merkle tree
    function computeHash(
        address sender,
        address receiver,
        uint256 tokenId,
        string memory tokenURI
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender, receiver, tokenId, tokenURI));
    }
}

contract MerkleTree {
    bytes32[] public hashes;
    uint256 public nSlots = 8;
    uint256 public nMinted;

    constructor() {
        hashes = new bytes32[](2 * nSlots - 1);
    }

    // Add an Item to the merkle tree
    function addItem(bytes32 hash) external {
        require(nMinted < nSlots, "Maximum number of mints reached");
        hashes[nMinted++] = hash;
        constructMerkleTree();
    }

    // whenever item is added reconstruct the merkle tree
    function constructMerkleTree() internal {
        uint256 n = nSlots;
        uint256 index = nSlots;
        uint256 offset = 0;

        while (n > 0) {
            for (uint256 i = 0; i < n - 1; i += 2) {
                hashes[index++] = (
                    keccak256(
                        abi.encodePacked(
                            hashes[offset + i],
                            hashes[offset + i + 1]
                        )
                    )
                );
            }
            offset += n;
            n = n / 2;
        }
    }

    // get the root hash of the merkle tree
    function getRoot() public view returns (bytes32) {
        return hashes[hashes.length - 1];
    }
}
