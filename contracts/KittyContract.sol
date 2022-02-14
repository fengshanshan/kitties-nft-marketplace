// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";

contract Kittycontract is IERC721, Ownable {

    mapping(uint256 =>address) private _kittyIndexToOwner;

    mapping(address =>uint256) private _ownershipTokenCount;

    mapping(uint256 =>address) private _kittyIndexToApproved;
    //approval the operator whole access
    mapping(address =>mapping (address=>bool)) private _operatorApprovals;


    uint256 totalNum = 10;

    string public override name = "Kitty";

    string public override symbol = "FT";

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

    bytes4 internal constant ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

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
        return _kittyIndexToOwner[_tokenId] == _operator ||
            _kittyIndexToApproved[_tokenId] == _operator ||
            _operatorApprovals[_kittyIndexToOwner[_tokenId]][_operator];
    }

    function getKitty (uint256 tokenId) external view returns (Kitty memory) 
    {
        return Kitties[tokenId];
    }

    function ownerOf(uint256 tokenId) external view override returns (address owner) 
    {
        return _kittyIndexToOwner[tokenId];
    }

    function balanceOf(address owner) external view override returns (uint256) {
        return _ownershipTokenCount[owner];
    }

    function totalSupply() external view override returns (uint256 total)
    {
        return Kitties.length;
    }

    function transfer(address to, uint256 tokenId) external override {
        require(_own(msg.sender, tokenId));
        _approve(to, tokenId);
        emit Transfer(msg.sender, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external override {
        require(_own(msg.sender, tokenId));
        _approve(to, tokenId);
        emit Approval(msg.sender, to, tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        require(_operator != msg.sender);
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 tokenId) external view override returns (address) {
        require(tokenId < Kitties.length);

        return _kittyIndexToApproved[tokenId];
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operatorApprovals[owner][operator]; 
    }


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external override {
        _transferFrom(from, to, tokenId);
        require( _checkERC721Support(from, to, tokenId, data) );
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        _transferFrom(_from, _to, _tokenId);
        require( _checkERC721Support(_from, _to, _tokenId, "") );
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) internal onlyOperator(_tokenId) {
        require(_isTokenValid(_tokenId));
        require(_to != address(0));
        require(_isOwner(_from, _tokenId));
        require(_tokenId < Kitties.length);

        _transfer(_from, _to, _tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) external override {
        _transferFrom(from, to, tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // update ownership
        _kittyIndexToOwner[_tokenId] = _to;
        // update ownership count
        if (_from != address(0)) {
            _ownershipTokenCount[_from]--;//_ownershipTokenCount[from].sub(1);
            delete _kittyIndexToApproved[_tokenId];
        }
        _ownershipTokenCount[_to]++;//_ownershipTokenCount[to].add(1);     
    }

    function _own(address _claimit, uint256 _tokenId) internal view returns (bool) {
        return _kittyIndexToOwner[_tokenId] == _claimit;
    }

    function _approve(address _approved, uint256 _tokenId) internal {
        _kittyIndexToApproved[_tokenId] = _approved;
    }


    function _approveFor(address _approved, uint256 _tokenId) internal view returns (bool) {
        return _kittyIndexToApproved[_tokenId] == _approved;
    }

    function _isTokenValid (uint256 _tokenId) private view returns (bool) {
        return _tokenId < Kitties.length;
    }

    function _isOwner (address _from, uint256 _tokenId) private view returns (bool) {
        return _kittyIndexToOwner[_tokenId] == _from;
    }

    function _checkERC721Support (address _from, address _to, uint256 _tokenId, bytes memory data) internal returns (bool) {
        if ( !_isContract(_to) ) {
            return true;
        }
        bytes4 returnData = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, data);
        return returnData == ERC721_RECEIVED;
    }

    function _isContract (address _to) internal view returns (bool) {
        uint32 size;
        assembly{
            size := extcodesize(_to)
        }
        return size > 0;
    }

    function _mixGenes (uint256 _dadGenes, uint256 _mumGenes) internal pure returns (uint256) {
        uint256 div = 100000000;
        uint256 firstHalf = _dadGenes / div;
        uint256 secondHalf = _mumGenes % div;
        return firstHalf*div + secondHalf;
    }

}