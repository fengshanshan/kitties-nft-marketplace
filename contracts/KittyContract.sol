// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";

contract Kittycontract is IERC721, Ownable {

    mapping(uint256 =>address) public kittyIndexToOwner;

    mapping(address =>uint256) ownershipTokenCount;

    mapping(uint256 =>address) public kittyIndexToApproved;
    //approval the operator whole access
    mapping(address =>mapping (address=>bool)) private _operatorApprovals;


    uint256 totalNum = 10;

    string public constant name = "Kitty";

    string public constant symbol = "FT";

    struct Kitty {
        uint256 genes;
        uint64 birthTime;
        uint32 mumId;
        uint32 dadId;
        uint16 generation;
    }


    Kitty[] Kitties;

    uint256 public gen0Counter;
    uint16 _gen0Counter;
    uint256 public constant CREATION_LIMIT_GEN0 = 100;

    event Birth(address indexed owner, uint256 indexed tokenId, uint256 mumId, uint256 dadId, uint256 genes);

    modifier onlyOperator (uint256 tokenId) {
        require(_checkOperator(msg.sender, tokenId));
        _;
    }

    function createKittyGen0 (uint256 _genes) public OnlyOwner returns (uint256) {
        require(_gen0Counter < CREATION_LIMIT_GEN0, "Gen 0 limit reached");
        _gen0Counter++;
        return _createKitty(
            0,
            0,
            0,
            _genes,
            msg.sender
        );
    }

    function _createKitty (
        uint256 _mumId,
        uint256 _dadId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    ) private returns (uint256)
    {
        Kitty memory _kitty = Kitty({
            genes: _genes,
            birthTime: uint64(block.timestamp),
            mumId: uint32(_mumId),
            dadId: uint32(_dadId),
            generation: uint16(_generation)
        });
        Kitties.push(_kitty);
        uint256 newTokenId = Kitties.length - 1;
        
        emit Birth(_owner, newTokenId, _mumId, _dadId, _genes);
        _transfer(address(0), _owner, newTokenId);
        return newTokenId;
    }

    function _checkOperator (address _operator, uint256 _tokenId) private view returns (bool) {
        return kittyIndexToOwner[_tokenId] == _operator ||
            kittyIndexToApproved[_tokenId] == _operator ||
            _operatorApprovals[kittyIndexToOwner[_tokenId]][_operator];
    }

    function getKitty (uint256 tokenId) external view returns (Kitty memory) {
        return Kitties[tokenId];
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return kittyIndexToOwner[_tokenId];
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return ownershipTokenCount[_owner];
    }

    function transfer(address _to, uint256 _tokenId) external {
        require(_own(msg.sender, _tokenId));
        _approve(_to, _tokenId);
        emit Transfer(msg.sender, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) external {
        require(_own(msg.sender, _tokenId));
        _approve(_to, _tokenId);
        emit Approval(msg.sender, _to, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != msg.sender);
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_tokenId < Kitties.length);

        return kittyIndexToApproved[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return _operatorApprovals[_owner][_operator]; 
    }


    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external {

    }


    function transferFrom(address _from, address _to, uint256 _tokenId) external{
        require(_to != address(0));
        require(_from == msg.sender || _approveFor(msg.sender, _tokenId) || this.isApprovedForAll(_from, _to));
        require(_own(_from, _tokenId));
        require(_tokenId < Kitties.length);

        _transfer(_from, _to, _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        kittyIndexToOwner[_tokenId] = _to;      
    }

    function _own(address _claimit, uint256 _tokenId) internal view returns (bool) {
        return kittyIndexToOwner[_tokenId] == _claimit;
    }

    function _approve(address _approved, uint256 _tokenId) internal {
        kittyIndexToApproved[_tokenId] = _approved;
    }


    function _approveFor(address _approved, uint256 _tokenId) internal pure returns (bool) {
        return kittyIndexToApproved[_tokenId] == _approved;
    }

}