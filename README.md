# FollowMe Smart Contract

Smart contract for the **FollowMe** mini-app.

🟢 **Live at**: [profile.link/followme@B197](https://profile.link/followme@B197)

---

## 🚀 Deploy

```bash
# Install dependencies
npm install

# Create .env file with your private key
# .env
PRIVATE_KEY=your-private-key-here
```

### 🧪 Testnet Deployment

```bash
npx hardhat ignition deploy --network lukso-testnet ./ignition/modules/FollowMe.js
```

### 🌐 Mainnet Deployment

```bash
npx hardhat ignition deploy --network lukso-mainnet ./ignition/modules/FollowMe.js
```

---

## ✅ Verify

```bash
npx hardhat verify --network lukso-mainnet CONTRACT_ADDRESS
```
