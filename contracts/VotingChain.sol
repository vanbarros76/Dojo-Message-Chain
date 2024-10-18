// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MsgChain.sol";
import "./MsgChainNFT.sol";

/**
 * @title VotingChain
 * @dev Sistema de votação para propostas de mensagens, com recompensas em tokens ERC20 e NFTs.
 */
contract VotingChain is Ownable {
    // Referência para os contratos de tokens e NFTs
    MsgChain public msgToken;
    MsgChainNFT public msgNFT;

    // Recompensas configuráveis para votar e propor mensagens
    uint256 public voteReward = 10 * 10 ** 18;       // Recompensa ao votar
    uint256 public proposalReward = 100 * 10 ** 18;  // Recompensa para a mensagem vencedora
    uint256 public nftCost = 200 * 10 ** 18;         // Custo em tokens para resgatar um NFT

    // Estrutura que armazena informações sobre cada proposta de mensagem
    struct Proposal {
        address proposer;  // Endereço do proponente
        string message;    // Texto da mensagem proposta
        uint256 voteCount; // Contador de votos para a proposta
        bool rewarded;     // Indica se a proposta já recebeu a recompensa
    }

    // Array para armazenar todas as propostas
    Proposal[] public proposals;
    // Mapeamento para rastrear se um usuário já votou
    mapping(address => bool) public hasVoted;
    // Contador de ciclos de votação
    mapping(address => uint256) public lastVotedCycle;
    // Contador do ciclo atual
    uint256 public currentCycle;
    // ID da última proposta vencedora
    uint256 public lastWinningProposalId;
    // Controle de tempo para o fim da votação
    uint256 public votingEndTime;
    // Duração de cada ciclo de votação (1 dia)
    uint256 public votingDuration = 1 days;
    // Índice inicial para exibir propostas
    uint256 public startIndex = 0;

    // Eventos que serão emitidos para registrar ações importantes
    event ProposalCreated(uint256 proposalId, address indexed proposer, string message);
    event Voted(uint256 proposalId, address indexed voter);
    event ProposalWon(uint256 proposalId, string message, address indexed proposer);
    event NFTRedeemed(address indexed user);

    // Erros customizados para simplificar mensagens de erro
    error AlreadyVoted();
    error ProposalNotFound();
    error ProposalAlreadyRewarded();
    error VotingNotEnded();
    error VotingEnded();              
    error InsufficientTokens();       

    // Construtor para inicializar o contrato com endereços de MsgChain e MsgChainNFT
    constructor() Ownable(msg.sender) {
        // Faz o deploy de um novo contrato MsgChain e o atribui a msgToken
        MsgChain _msgToken = new MsgChain(1000000e18); // Defini o supply inicial
        _msgToken.transferOwnership(msg.sender);      // Transfere a propriedade para o dono do contrato
        msgToken = _msgToken;                          // Atribui o contrato de tokens

        // Faz o deploy de um novo contrato MsgChainNFT e o atribui a msgNFT
        MsgChainNFT _msgNFT = new MsgChainNFT();
        _msgNFT.transferOwnership(msg.sender); // Transfere a propriedade para o dono do contrato
        msgNFT = _msgNFT;                       // Atribui o contrato de NFTs
        
        votingEndTime = block.timestamp + votingDuration; // Define o tempo de término da votação
    }

    /**
     * @dev Função para propor uma nova mensagem.
     * @param newMessage O texto da nova mensagem a ser proposta.
     */
    function proposeMessage(string memory newMessage) external {
        proposals.push(Proposal(msg.sender, newMessage, 0, false));
        emit ProposalCreated(proposals.length - 1, msg.sender, newMessage);
    }

    /**
     * @dev Função para votar em uma proposta.
     * @param proposalId ID da proposta em que o usuário deseja votar.
     */
    function vote(uint16 proposalId) external {
        if (block.timestamp >= votingEndTime) revert VotingEnded();
        if (hasVoted[msg.sender]) revert AlreadyVoted();
        if (proposalId >= proposals.length) revert ProposalNotFound();

        // Contabiliza o voto e atualiza o status do usuário
        proposals[proposalId].voteCount++;
        lastVotedCycle[msg.sender] = currentCycle;

        // Emite tokens de recompensa para o votante
        msgToken.mintReward(msg.sender, voteReward);
        emit Voted(proposalId, msg.sender);
    }

    /**
     * @dev Função para finalizar a votação e recompensar o vencedor.
     */
    function finalizeVoting() external onlyOwner {
        if (block.timestamp < votingEndTime) revert VotingNotEnded();

        uint256 winningVoteCount = 0;
        uint256 winningProposalIndex = startIndex;

        for (uint256 i = startIndex; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalIndex = i;
            }
            hasVoted[proposals[i].proposer] = false; // Reseta o status de votação dos usuários
        }

        Proposal storage winningProposal = proposals[winningProposalIndex];
        if (!winningProposal.rewarded) {
            msgToken.mintReward(winningProposal.proposer, proposalReward);
            winningProposal.rewarded = true;
            emit ProposalWon(lastWinningProposalId, winningProposal.message, winningProposal.proposer);
        }

        startIndex = proposals.length;

        votingEndTime = block.timestamp + votingDuration;
    }

    /**
     * @dev Função para trocar tokens por um NFT.
     */
    function redeemNFT() external {
        uint256 userBalance = msgToken.balanceOf(msg.sender);
        if (userBalance < nftCost) revert InsufficientTokens();

        msgToken.transferFrom(msg.sender, address(this), nftCost);
        msgNFT.mintNFT(msg.sender);
        emit NFTRedeemed(msg.sender);
    }

    /**
     * @dev Funções de ajuste para recompensas e custo do NFT.
     *      Essas funções permitem que o dono do contrato ajuste os valores.
     */
    function setVoteReward(uint256 newVoteReward) external onlyOwner {
        voteReward = newVoteReward;
    }

    function setProposalReward(uint256 newProposalReward) external onlyOwner {
        proposalReward = newProposalReward;
    }

    function setNFTCost(uint256 newNFTCost) external onlyOwner {
        nftCost = newNFTCost;
    }
}