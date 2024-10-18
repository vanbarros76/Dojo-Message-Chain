let web3;
let contract;
let isConnected = false;

const CONTRACT_ADDRESS = '0x938a90c60Bc3995b46b5477f2892381Cd18fDfB3';
const ABI = [ {
    "inputs": [],
    "name": "getMessage",
    "outputs": [
      {
        "internalType": "string",
        "name": "",
        "type": "string"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "_message",
        "type": "string"
      }
    ],
    "name": "setMessage",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  // Adicione estas novas funções ao ABI
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "_proposalId",
        "type": "uint256"
      },
      {
        "internalType": "bool",
        "name": "_support",
        "type": "bool"
      }
    ],
    "name": "vote",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "string",
        "name": "_description",
        "type": "string"
      }
    ],
    "name": "propose",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "redeemNFT",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
];

async function initWeb3() {
    if (typeof window.ethereum !== 'undefined') {
        web3 = new Web3(window.ethereum);
        contract = new web3.eth.Contract(ABI, CONTRACT_ADDRESS);
        console.log('Web3 initialized');
    } else {
        console.error('MetaMask is not installed');
        alert('Por favor, instale uma carteira como MetaMask para interagir com este DApp.');
    }
}

async function connectWallet() {
    console.log('Attempting to connect wallet...');
    if (typeof window.ethereum !== 'undefined') {
        try {
            await window.ethereum.request({ method: 'eth_requestAccounts' });
            const accounts = await web3.eth.getAccounts();
            console.log('Connected account:', accounts[0]);
            isConnected = true;
            enableButtons();
            updateConnectButton(true);
            alert('Carteira conectada com sucesso!');
            return true;
        } catch (error) {
            console.error('Failed to connect to MetaMask:', error);
            isConnected = false;
            disableButtons();
            updateConnectButton(false);
            alert('Falha ao conectar a carteira. Por favor, tente novamente.');
            return false;
        }
    } else {
        console.error('MetaMask is not installed');
        alert('Por favor, instale uma carteira como MetaMask para interagir com este DApp.');
        return false;
    }
}

function updateConnectButton(connected) {
    const connectButton = document.getElementById('connect-wallet-button');
    if (connected) {
        connectButton.textContent = 'Carteira Conectada';
        connectButton.classList.add('connected');
    } else {
        connectButton.textContent = 'Conectar Carteira';
        connectButton.classList.remove('connected');
    }
}

function enableButtons() {
    document.getElementById('message-input').disabled = false;
    document.getElementById('set-message-button').disabled = false;
    document.getElementById('vote-button').disabled = false;
    document.getElementById('propose-button').disabled = false;
    document.getElementById('redeem-nft-button').disabled = false;
}

function disableButtons() {
    document.getElementById('message-input').disabled = true;
    document.getElementById('set-message-button').disabled = true;
    document.getElementById('vote-button').disabled = true;
    document.getElementById('propose-button').disabled = true;
    document.getElementById('redeem-nft-button').disabled = true;
}

async function loadMessage() {
    if (!isConnected) {
        alert('Por favor, conecte sua carteira primeiro.');
        return;
    }
    const messageBoard = document.getElementById('message-board');
    try {
        const message = await contract.methods.getMessage().call();
        messageBoard.innerText = message;
    } catch (error) {
        messageBoard.innerText = 'Erro ao carregar a mensagem.';
        console.error(error);
    }
}

async function setMessage() {
    if (!isConnected) {
        alert('Por favor, conecte sua carteira primeiro.');
        return;
    }
    const messageInput = document.getElementById('message-input');
    const setMessageButton = document.getElementById('set-message-button');
    const newMessage = messageInput.value;
    if (newMessage) {
        setMessageButton.innerHTML = 'Enviando...';
        setMessageButton.disabled = true;

        try {
            const accounts = await web3.eth.getAccounts();
            await contract.methods.setMessage(newMessage).send({ from: accounts[0] });
            messageInput.value = '';
            await loadMessage();
            alert('Mensagem enviada com sucesso!');
        } catch (error) {
            console.error(error);
            alert('Erro ao enviar a mensagem. Verifique o console para mais detalhes.');
        } finally {
            setMessageButton.innerHTML = 'Alterar Mensagem';
            setMessageButton.disabled = false;
        }
    } else {
        alert("Por favor, insira uma mensagem.");
    }
}

async function vote() {
    if (!isConnected) {
        alert('Por favor, conecte sua carteira primeiro.');
        return;
    }
    
    const proposalId = prompt('Digite o ID da proposta em que deseja votar:');
    if (proposalId === null) {
        return; // O usuário cancelou a entrada
    }
    
    const voteValue = confirm('Clique OK para votar a favor ou Cancelar para votar contra.');
    
    try {
        const accounts = await web3.eth.getAccounts();
        await contract.methods.vote(proposalId, voteValue).send({ from: accounts[0] });
        alert('Voto registrado com sucesso!');
    } catch (error) {
        console.error('Erro ao votar:', error);
        alert('Ocorreu um erro ao tentar votar. Por favor, verifique o console para mais detalhes.');
    }
}

async function propose() {
    if (!isConnected) {
        alert('Por favor, conecte sua carteira primeiro.');
        return;
    }
    
    const description = prompt('Digite a descrição da sua proposta:');
    if (description === null) {
        return; // O usuário cancelou a entrada
    }
    
    try {
      const accounts = await web3.eth.getAccounts();
      await contract.methods.propose(description).send({ from: accounts[0] });
      alert('Proposta enviada com sucesso!');
  } catch (error) {
      console.error('Erro ao propor:', error);
      alert('Ocorreu um erro ao tentar enviar a proposta. Por favor, verifique o console para mais detalhes.');
  }
}

async function redeemNFT() {
  if (!isConnected) {
      alert('Por favor, conecte sua carteira primeiro.');
      return;
  }
  
  const confirmRedeem = confirm('Você tem certeza que deseja resgatar o NFT? Esta ação não pode ser desfeita.');
  if (!confirmRedeem) {
      return; // O usuário cancelou a ação
  }
  
  try {
      const accounts = await web3.eth.getAccounts();
      await contract.methods.redeemNFT().send({ from: accounts[0] });
      alert('NFT resgatado com sucesso!');
  } catch (error) {
      console.error('Erro ao resgatar NFT:', error);
      alert('Ocorreu um erro ao tentar resgatar o NFT. Por favor, verifique o console para mais detalhes.');
  }
}

window.addEventListener('load', async () => {
    console.log('Page loaded');
    await initWeb3();
    document.getElementById('connect-wallet-button').addEventListener('click', connectWallet);
    document.getElementById('set-message-button').addEventListener('click', setMessage);
    document.getElementById('vote-button').addEventListener('click', vote);
    document.getElementById('propose-button').addEventListener('click', propose);
    document.getElementById('redeem-nft-button').addEventListener('click', redeemNFT);
    disableButtons(); // Initially disable buttons until wallet is connected
});

// Disconnect wallet when the page is refreshed or closed
window.addEventListener('beforeunload', function() {
    if (isConnected) {
        isConnected = false;
        disableButtons();
    }
});