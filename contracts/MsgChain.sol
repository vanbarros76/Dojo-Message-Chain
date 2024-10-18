// MsgChain.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MsgChain
 * @dev Token ERC20 usado para recompensar participantes de um sistema de votação.
 */
contract MsgChain is ERC20, Ownable {
    address public votingContract;

    error NotVotingContract();
    error VotingContractAlreadySet();

    modifier onlyVotingContract() {
        require(msg.sender == votingContract, NotVotingContract()) ;
        _;
    }

    constructor(uint256 initialSupply) ERC20("Messenger Token", "MSG") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev Define o endereço do contrato de votação autorizado a distribuir tokens.
     * @param _votingContract Endereço do contrato de votação.
     */
    function setVotingContract(address _votingContract) external onlyOwner {
        if (votingContract != address(0)) revert VotingContractAlreadySet();
        votingContract = _votingContract;
    }

    /**
     * @dev Função para permitir que o contrato de votação emita tokens de recompensa.
     * @param to Endereço do destinatário.
     * @param amount Quantidade de tokens a serem emitidos.
     */
    function mintReward(address to, uint256 amount) external onlyVotingContract {
        _mint(to, amount);
    }
}