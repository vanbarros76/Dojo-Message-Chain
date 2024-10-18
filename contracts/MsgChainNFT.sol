// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MsgChainNFT
 * @dev Contrato ERC721 para recompensar usuários com NFTs únicos.
 */
contract MsgChainNFT is ERC721, Ownable {
    uint256 public nextTokenId;
    address public votingContract;

    mapping(uint256 => string) private _tokenMetadata;

    event VotingContractSet(address indexed votingContract);
    event NFTMinted(address indexed recipient, uint256 indexed tokenId);
    event MetadataSet(uint256 indexed tokenId, string metadata);

    error Unauthorized();
    error MetadataAlreadySet();
    error VotingContractAlreadySet(address votingContract);

    modifier onlyVotingContract() {
        if (msg.sender != votingContract) revert Unauthorized();
        _;
    }

    constructor() ERC721("Messenger NFT", "MNFT") Ownable(msg.sender) {}

    /**
     * @dev Define o contrato de votação autorizado a mintar NFTs. Pode ser chamado apenas uma vez.
     * @param _votingContract Endereço do contrato de votação.
     */
    function setVotingContract(address _votingContract) external onlyOwner {
        require(votingContract == address(0), VotingContractAlreadySet(votingContract));
        votingContract = _votingContract;
        emit VotingContractSet(votingContract);
    }

    /**
     * @dev Função para mintar um novo NFT. Pode ser chamada apenas pelo contrato de votação.
     * @param recipient Endereço do usuário que receberá o NFT.
     */
    function mintNFT(address recipient) external onlyVotingContract {
        _safeMint(recipient, nextTokenId);
        emit NFTMinted(recipient, nextTokenId);
        nextTokenId++;
    }

    /**
     * @dev Define metadados personalizados para cada NFT. Pode ser chamado apenas uma vez por token.
     * @param tokenId ID do token.
     * @param metadata URL dos metadados.
     */
    function setTokenMetadata(uint256 tokenId, string memory metadata) external onlyOwner {
        require(bytes(_tokenMetadata[tokenId]).length == 0, MetadataAlreadySet());
        _tokenMetadata[tokenId] = metadata;
        emit MetadataSet(tokenId, metadata);
    }

    /**
     * @dev Retorna os metadados de um NFT específico.
     * @param tokenId ID do token.
     * @return URL dos metadados do token.
     */
    function tokenMetadata(uint256 tokenId) external view returns (string memory) {
        return _tokenMetadata[tokenId];
    }
}