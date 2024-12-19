# Ludo Gaming Platform

Ludo is a decentralized gaming platform built on the Stacks blockchain that enables players to participate in games, own in-game assets, and trade them in a secure marketplace.

## Features

- Player registration and profile management
- Game creation and participation
- NFT-based game assets
- Marketplace for trading game items
- Achievement and rewards system
- Built on Stacks blockchain with Clarity smart contracts

## Smart Contract Overview

The smart contract provides the following core functionalities:

### Player Management
- Register new players with usernames
- Track player statistics (games played, wins)
- Manage player's active games and NFT balance

### Game Management
- Create new games with customizable stakes
- Join existing games
- Track game status and winners
- Handle game completion and rewards

### Asset System
- Mint new game assets (NFTs)
- List assets for sale
- Purchase assets from other players
- Track asset ownership and metadata

## Getting Started

### Prerequisites

- Stacks wallet (Hiro Wallet recommended)
- Some STX tokens for transaction fees
- Basic understanding of blockchain interactions

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/ludo.git
cd ludo
```

2. Install dependencies
```bash
npm install
```

3. Deploy the contract
```bash
clarinet deploy
```

## Usage

### Player Registration
```clarity
(contract-call? .ludo register-player "PlayerName")
```

### Creating a Game
```clarity
(contract-call? .ludo create-game u100) ;; Creates game with 100 STX stake
```

### Joining a Game
```clarity
(contract-call? .ludo join-game u1) ;; Join game with ID 1
```

### Minting Assets
```clarity
(contract-call? .ludo mint-game-asset "Legendary Sword" "Legendary" u1000)
```

## Development

### Testing

Run the test suite:
```bash
clarinet test
```

### Local Development
1. Start local Clarinet chain:
```bash
clarinet integrate
```

## Security Considerations

- All transactions require appropriate authorization
- Asset ownership is verified before transfers
- Game stakes are locked during gameplay
- Admin functions are protected

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
