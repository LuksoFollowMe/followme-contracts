Smartcontract for FollowMe mini-app.

Live at profile.link/followme@B197

Deploy:

- npm install
- Create .env file, with PRIVATE_KEY=your-private-key-here
- Testnet run: npx hardhat ignition deploy --network lukso-testnet ./ignition/modules/FollowMe.js
- Mainnet run: npx hardhat ignition deploy --network lukso-mainnet ./ignition/modules/FollowMe.js

Verify:

- npx hardhat verify --network lukso-mainnet CONTRACT_ADDRESS 0xf01103E5a9909Fc0DBe8166dA7085e0285daDDcA
