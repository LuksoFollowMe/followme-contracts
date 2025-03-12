require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("@nomicfoundation/hardhat-verify");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */

module.exports = {
	solidity: "0.8.28",
	networks: {
		hardhat: {
			forking: {
				url: "https://42.rpc.thirdweb.com",
				enabled: true,
			},
		},
		"lukso-testnet": {
			live: true,
			url: "https://rpc.testnet.lukso.network",
			chainId: 4201,
			accounts: [process.env.PRIVATE_KEY],
		},
		"lukso-mainnet": {
			live: true,
			url: "https://42.rpc.thirdweb.com",
			chainId: 42,
			accounts: [process.env.PRIVATE_KEY],
		},
	},
	etherscan: {
		apiKey: {
			"lukso-mainnet": "empty",
		},
		customChains: [
			{
				network: "lukso-mainnet",
				chainId: 42,
				urls: {
					apiURL: "https://explorer.execution.mainnet.lukso.network/api",
					browserURL: "https://explorer.execution.mainnet.lukso.network",
				},
			},
		],
	},
};
